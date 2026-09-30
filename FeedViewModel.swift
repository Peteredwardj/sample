//
//  FeedViewModel.swift
//  Hudel
//
//  Created by Peter Jonathan on 2023-08-17.
//

import Foundation

class FeedViewModel: ObservableObject{
    @Published var clubRecs = [Club]()
    @Published var friendRecs = [UserInfo]()
    @Published var posts = [Post]()
    @Published var events = [Event]()
    @Published var error: Error?
    @Published var likedPosts = [UUID]()
    @Published var unlikedPosts = [UUID]()
    @Published var forceRefresh = false
    @Published var positionFriends = -1

    
    let BASE_URL = "https://api.clubl.io/feed"
    
    private func updatePost(_ post: Post) {
           if let index = posts.firstIndex(where: { $0.id == post.id }) {
               posts[index] = post
           } else {
               posts.insert(post, at: 0)
           }
       }
    
    private func updateEvents(_ event: Event) {
           if let index = events.firstIndex(where: { $0.id == event.id }) {
               events[index] = event
           } else {
               events.insert(event, at: 0)
           }
       }
    
    private func updateClub(_ club: Club){
        if let index = clubRecs.firstIndex(where: {$0.id == club.id}){
            clubRecs[index] = club
        }else{
            clubRecs.append(club)
        }
    }
    
    private func updateFriend(_ friend: UserInfo){
        if let index = friendRecs.firstIndex(where: {$0.user_id == friend.user_id}){
            friendRecs[index] = friend
        }else{
            friendRecs.append(friend)
        }
        
    }
    
    
    func refreshData(token: String) {
        Task {
            do {
                if let refreshedPosts = try await getPostFeed(token: token) {
                    DispatchQueue.main.async {
                        // Remove posts that are no longer present in the refreshed data
                        self.posts.removeAll { post in
                            !refreshedPosts.contains { refreshedPost in
                                refreshedPost.id == post.id
                            }
                        }

                        // Update or insert refreshed posts
                        for refreshedPost in refreshedPosts {
                            self.updatePost(refreshedPost)
                        }

                        // Sort posts by createdTime
                        self.posts = refreshedPosts.sorted(by: { post1, post2 in
                            guard let date1 = DateFormatter.customDateFormatter.date(from: post1.createdTime),
                                  let date2 = DateFormatter.customDateFormatter.date(from: post2.createdTime) else {
                                return false
                            }
                            return date1 > date2
                        })
                    }
                }
            } catch {
                print("\(error)")
                self.error = error
            }
        }
    }
    
    func refreshEvents(token: String) {
        Task {
            do {
                if let refreshedEvents = try await getEventFeed(token: token) {
                    DispatchQueue.main.async {
                        // Remove posts that are no longer present in the refreshed data
                        self.events.removeAll { event in
                            !refreshedEvents.contains { refreshedEvent in
                                refreshedEvent.id == event.id
                            }
                        }

                        // Update or insert refreshed posts
                        for refreshedEvent in refreshedEvents {
                            self.updateEvents(refreshedEvent)
                        }


                    }
                }
            } catch {
                print("\(error)")
               // self.error = error
            }
        }
    }


    
    func refreshClubRecs(token: String) {
            Task {
                do {
                    if let refreshedClubs = try await getClubRecs(token: token) {
                        DispatchQueue.main.async {
                            for refreshedClub in refreshedClubs {
                                self.updateClub(refreshedClub)
                            }
                        }
                    }
                } catch {
                    print("\(error)")
                   // self.error = error
                }
            }
        }
    
    func refreshFriendRecs(token: String) {
            Task {
                do {
                    if let refreshedFriends = try await getFriendsRecs(token: token) {
                        DispatchQueue.main.async {
                            for refreshedFriend in refreshedFriends {
                                self.updateFriend(refreshedFriend)
                            }
                        }
                    }
                } catch {
                    print("\(error)")
                }
            }
        }
    
}

extension
FeedViewModel{
    @MainActor
    func getPostFeed(token:String) async throws -> [Post]? {
        do{
            let urlString = BASE_URL
            guard let url = URL(string: urlString) else{
                throw CommonRequestError.invalidURL
            }
            
            var request = URLRequest(url:url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw CommonRequestError.serverError
            }
            
            let decoder = JSONDecoder()
            let fetchedPosts = try decoder.decode([Post].self, from: data)
        
            
            return fetchedPosts.isEmpty ? nil : fetchedPosts
            
            
        }
        catch{
            print("\(error)")
            self.error = error
            throw error
            
        }
        
    }
    
    @MainActor
    func getEventFeed(token:String) async throws -> [Event]? {
        do{
            let urlString = BASE_URL + "/events-rec"
            guard let url = URL(string: urlString) else{
                throw CommonRequestError.invalidURL
            }
            
            var request = URLRequest(url:url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw CommonRequestError.serverError
            }
            
            let decoder = JSONDecoder()
            let fetchedEvents = try decoder.decode([Event].self, from: data)
        
            
            return fetchedEvents.isEmpty ? nil : fetchedEvents
            
            
        }
        catch{
            print("\(error)")
            self.error = error
            throw error
            
        }
        
    }
    
    @MainActor
    func getClubRecs(token:String) async throws -> [Club]? {
        do{
            let urlString = BASE_URL + "/clubs"
            guard let url = URL(string: urlString) else{
                throw CommonRequestError.invalidURL
            }
            
            var request = URLRequest(url:url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw CommonRequestError.serverError
            }
            
            let decoder = JSONDecoder()
            let fetchedClubs = try decoder.decode([Club].self, from: data)
        
            
            return fetchedClubs.isEmpty ? nil : fetchedClubs
            
            
        }
        catch{
            print("\(error)")
            self.error = error
            throw error
            
        }
        
    }
    
    @MainActor
    func getFriendsRecs(token:String) async throws -> [UserInfo]? {
        do{
          
            let urlString = BASE_URL + "/friends-rec"
            guard let url = URL(string: urlString) else{
                throw CommonRequestError.invalidURL
            }
            
            var request = URLRequest(url:url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw CommonRequestError.serverError
            }
            
            let decoder = JSONDecoder()
            let fetchedFriends = try decoder.decode([UserInfo].self, from: data)
        
            
            return fetchedFriends.isEmpty ? [] : fetchedFriends
            
            
        }
        catch{
            print("\(error)")
            self.error = error
            throw error
            
        }
        
    }
}
