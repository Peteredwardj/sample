//
//  MessageViewModel.swift
//  Hudel
//
//  Created by Peter Jonathan on 2023-09-06.
//

import Firebase
import FirebaseFirestoreSwift

class MessageViewModel: ObservableObject {
    private var db = Firestore.firestore()
    var firestoreListener: ListenerRegistration?
    @Published var messages: [Message] = []
    @Published var readMessageIds: Set<String> = Set()
    @Published var count = 0
    
    
    init() {
        if let savedReadMessageIds = UserDefaults.standard.array(forKey: "ReadMessageIds") as? [String] {
            readMessageIds = Set(savedReadMessageIds)
        }
    }
    
    func markMessageAsRead(_ messageId: String) {
        readMessageIds.insert(messageId)
        UserDefaults.standard.set(Array(readMessageIds), forKey: "ReadMessageIds")
    }
    
    func isMessageRead(_ messageId: String) -> Bool {
        return readMessageIds.contains(messageId)
    }
    
    func sendMessage(sender: UserInfo, content: String, isMedia: Bool, inGroup groupID: String, channel: Channel) {
        let newMessage = Message(id: UUID().uuidString, sender: sender, content: content, isMedia: isMedia, timestamp: Date(), channel: channel)
        
        do {
            try db.collection("groups").document(groupID)
                .collection(channel.rawValue)
                .document(newMessage.id)
                .setData(from: newMessage)
            self.count += 1
        } catch {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    func sendAnnouncementNotification(clubId: UUID, token: String)async{
        do{
            let urlString = "https://api.clubl.io/clubs/notifyMembers"
            guard let url = URL(string: urlString) else{
                throw CommonRequestError.invalidURL
            }
            
            let body: [String: Any] = [
                "clubId": clubId.uuidString,
            ]
            
            let contentType = "application/json"
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
                request.httpBody = jsonData
            } catch {
                throw CommonRequestError.serializationError
            }
            
            let (_, response) = try await URLSession.shared.data(for:request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw CommonRequestError.serverError
            }
        }
        
        catch {
            print("\(error)")
        }
        
    }
    
    
    
    func fetchMessages(inGroup clubId: String, channel: Channel) {
        firestoreListener?.remove()
        firestoreListener = db.collection("groups").document(clubId)
            .collection(channel.rawValue)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                
                var newMessages: [Message] = []
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        do {
                            let cm = try change.document.data(as: Message.self)
                            self.messages.append(cm)
                        } catch {
                            print("Failed to decode message: \(error)")
                        }
                    }
                }
                
                
                DispatchQueue.main.async {
                    self.count += newMessages.count
                }
                DispatchQueue.main.async {
                    self.count += newMessages.count
                }
            }
    }
    
    func removeListener(){
        firestoreListener?.remove()
    }
}






