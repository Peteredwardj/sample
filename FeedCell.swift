//
//  FeedCell.swift
//  Clubl
//
//  Created by Peter Jonathan on 2023-07-03.
//

import SwiftUI
import CachedAsyncImage

struct FeedCell: View {
    var club = ClubMockData.club //optional
    let post: Post
    var showClub = true
    @State var showFullImage = false
    @State var liked = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var postViewModel: PostViewModel
    @Environment(\.colorScheme) var colorScheme
    @State var likeCount = 0
    @State  var isCommentSheetPresented = false
    @State private var selectedClub:Club = ClubMockData.club
    @State private var displayClubView = false
    @State private var shouldDismiss = false
    
    
    @Binding var deletedPosts:[UUID]
    
    @State var isAtFullView = false
    
    var showClubNavButton = false
    
    
    
    
    var body: some View {
        if (!isAtFullView){
            NavigationLink {
                FeedPostFullView(postId: post.id)
                    .environmentObject(postViewModel)
                    .navigationBarBackButtonHidden(true)
            } label: {
                cellContent
            }
            /*.sheet(isPresented: $isCommentSheetPresented) {
             FeedComment(isPresented: $isCommentSheetPresented, postID: post.id, comments: post.comments)
             }*/
        }
        else{
            cellContent
        }
        
        
    }
    
    
}


extension FeedCell{
    var cellContent: some View{
        VStack {
            VStack(alignment: .leading,spacing:5){
                HStack(alignment: .top, spacing: 12){
                    userPicButton(imageLink: post.userInfo.imageURL, userId: post.userInfo.user_id)
                        .padding(.leading)
                    
                    HStack{
                        VStack(alignment: .leading, spacing: 2){
                            
                            if (showClub){
                                HStack(spacing:3){
                                    CachedAsyncImage(url: URL(string: post.clubImage),urlCache: .imageCache) { image in
                                        image
                                            .resizable()
                                            .frame(width: 17, height: 17)
                                            .cornerRadius(5)
                                        
                                    } placeholder: {
                                        Color.mainColor
                                            .frame(width: 17, height: 17)
                                            .cornerRadius(5)
                                        
                                    }
                                    
                                    Text(post.clubName)
                                        .font(.subheadline).bold()
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    //.font(.system(size:12))
                                    //.foregroundColor(.secondary)
                                    if (showClubNavButton){
                                        Button {
                                            Task{
                                                do{
                                                    selectedClub =  try await fetchClubById(id: post.clubId, token: authViewModel.userToken!)
                                                    displayClubView = true
                                                }
                                            }
                                            
                                        } label: {
                                            /*RoundedRectangle(cornerRadius: 5)
                                             .frame(width:30,height:25)
                                             .overlay{*/
                                            HStack(spacing:3){
                                                Image(systemName: "arrow.up.forward.circle.fill")
                                                    .font(.caption)
                                                
                                                /*Text("Club")
                                                 .font(.caption)
                                                 .fontWeight(.bold)*/
                                            }
                                            .foregroundColor(.mainColor)
                                            
                                            // }
                                            
                                        }
                                        .sheet(isPresented: $displayClubView) {
                                            ClubView(shouldDismiss: $shouldDismiss, club: selectedClub, showNavBar: false)
                                            
                                        }
                                        .onChange(of: displayClubView) { newValue in
                                            selectedClub = selectedClub
                                        }
                                        
                                    }
                                    
                                    
                                }
                                .padding(.top,6)
                                HStack{
                                    userHandleButton(userId: post.userInfo.user_id, handle: post.userInfo.handle, feedView: true)
                                    Spacer()
                                    
                                }
                            }
                            else{
                                Spacer()
                                HStack{
                                    userHandleButton(userId: post.userInfo.user_id, handle: post.userInfo.handle)
                                    Spacer()
                                    
                                    
                                }
                                Spacer()
                                
                                
                            }
                            
                            
                            
                        }
                    }
                    .padding(.bottom,5)
                    
                    if (post.author == authViewModel.userId || club.admins.contains(authViewModel.userId!)){ //allow admins to delete
                        Menu {
                            Button {
                                Task{
                                    do{
                                        try await postViewModel.deletePost(postId: post.id, token: authViewModel.userToken!)
                                        deletedPosts.append(post.id)
                                    }
                                    catch{
                                        print("Error deleting post \(error)")
                                    }
                                }
                                
                                
                            } label: {
                                Text("Delete")
                                    .foregroundColor(.red)
                            }
                            
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15))
                                .frame(width:30, height: 30)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                    }
                    
                    else{
                        Menu {
                            Button {
                                sendReportEmail(postURL: "https://hudel.co/post/\(post.id)")
                                
                                
                            } label: {
                                Text("Report")
                                    .foregroundColor(.red)
                            }
                            
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 15))
                                .frame(width:30, height: 30)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                    }
                }
                
                //caption
                //Text(post.content)
                Text(.init(formatLinksInContent()))
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .padding(.leading)
                    .padding(.trailing,5)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                
                //media
                if (post.media.count > 0) {
                    Button(action: {
                        self.showFullImage = true
                    }) {
                        CachedAsyncImage(url: URL(string: post.media.first!), urlCache: .imageCache) { phase in
                            switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .edgesIgnoringSafeArea(.all)
                                        .padding(.horizontal)

                                case .failure(_):
                                    // Don't display anything if the image fails to load
                                    EmptyView()

                                case .empty:
                                    Color.mainColor
                                        .frame(width: 50, height: 50)
                                        .padding(.leading)

                                @unknown default:
                                    // Fallback for future cases
                                    EmptyView()
                            }
                        }
                    }
                    
                    .fullScreenCover(isPresented: $showFullImage, content: {
                        FullImageView(imageUrl: post.media.first!, isPresented: $showFullImage)
                    })
                    
                }
                
                
                
                
                VStack(spacing:0){
                    //Buttons
                    HStack{
                        if let date = getDateFromString(post.createdTime) {
                            Text(getPostFormattedDate(date: date))
                                .foregroundColor(.gray)
                                .font(.caption2)
                                .padding(.top,20)
                            
                        }
                        Spacer()
                    }
                    .padding(.leading)
                    HStack(){
                        
                        /*Button {
                         } label: {
                         Image(systemName: "square.and.arrow.up")
                         .font(.subheadline)
                         
                         }*/
                        
                        
                        Spacer()
                        
                        Button {
                            Task {
                                do {
                                    likeCount += liked ? -1 : 1
                                    liked.toggle() //make animation smoother
                                    try await postViewModel.likePost(postId: post.id, token: authViewModel.userToken!)
                                } catch {
                                    print("Failed to like/unlike \(error)")
                                }
                            }
                            
                        } label: {
                            Image(systemName: liked ? "star.fill" : "star")
                                .font(.system(size:15))
                                .foregroundColor(liked ? .yellow : .gray)
                            
                            //Text("\(post.likes.count + likeOffset > 0 ? post.likes.count + likeOffset : 0)")
                            Text("\(likeCount)")
                                .font(.system(size:13))
                                .frame(width: 20)
                        }
                        .fixedSize()
                        
                        
                        Spacer()
                        
                        
                        
                        /*Button {
                         isCommentSheetPresented.toggle()
                         
                         }*/
                        NavigationLink {
                            FeedPostFullView(postId: post.id)
                                .environmentObject(postViewModel)
                            .navigationBarBackButtonHidden(true)}
                    label: {
                        Image(systemName: "bubble.left")
                            .font(.system(size:15))
                        
                        Text("\(post.comments.count)")
                            .font(.system(size:13))
                            .frame(width: 20)
                        
                    }
                    .fixedSize()
                    .disabled(isAtFullView)
                        
                        Spacer()
                        
                        
                        
                    }.padding().foregroundColor(.gray)
                    Divider()
                }
                
            }
        }
        .padding(.all,3)
        .onAppear{
            liked = ((post.likes.contains { like in
                like.userID == authViewModel.userId
            }))
            
            likeCount = post.likes.count
        }
        
    }
    
    func formatLinksInContent() -> String {
        let regexPattern = #"\b(https?://\S+)\b"#
        let nsRange = NSRange(post.content.startIndex..<post.content.endIndex, in: post.content)
        
        if let regex = try? NSRegularExpression(pattern: regexPattern),
           let match = regex.firstMatch(in: post.content, options: [], range: nsRange) {
            let linkRange = Range(match.range, in: post.content)!
            let linkText = post.content[linkRange]
            
            let prefixText = post.content.prefix(upTo: linkRange.lowerBound)
            let suffixText = post.content.suffix(from: linkRange.upperBound)
            
            let formattedText = "[\(linkText)](\(String(linkText)))"
            
            return "\(prefixText)\(formattedText)\(suffixText)"
        } else {
            return post.content
        }
    }
}


struct FullImageView: View {
    var imageUrl: String
    @Binding var isPresented: Bool
    
    var body: some View {
        if let url = URL(string: imageUrl) {
            VStack {
                Spacer()
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .edgesIgnoringSafeArea(.all)
                } placeholder: {
                    Color.mainColor
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                }
                Spacer()
                Button(action: {
                    isPresented = false // Close the view when the button is tapped
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.mainColor)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    
}

struct userPicButton: View{
    @State private var selectedFriend:String = ""
    @State private var displayFriendView = false
    let imageLink: String
    let userId: String
    var isCommentView = false
    var body: some View{
        
        Button {
            selectedFriend = userId
            displayFriendView = true
            
        } label: {
            CachedAsyncImage(url: URL(string: imageLink), urlCache: .imageCache) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: isCommentView ? 35 : 47, height: isCommentView ? 35 : 47)
            } placeholder: {
                Color.mainColor
                    .clipShape(Circle())
                    .frame(width: isCommentView ? 35 : 47, height: isCommentView ? 35 : 47)
            }
        }
        .sheet(isPresented: $displayFriendView) {
            FriendProfileView(userId: selectedFriend)
            
        }
        .onChange(of: displayFriendView) { newValue in
            selectedFriend = selectedFriend
        }
        
        
    }
}

struct userHandleButton: View{
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedFriend:String = ""
    @State private var displayFriendView = false
    let userId: String
    let handle: String
    
    var feedView = false
    var body: some View{
        
        
        Button {
            selectedFriend = userId
            displayFriendView = true
            
        } label: {
            if (feedView){
                Text("@\(handle)")
                    .font(.system(size:14))
                    .foregroundColor(.secondary)
            }
            else{
                Text("@\(handle)")
                    .font(.subheadline).bold()
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            
        }
        .sheet(isPresented: $displayFriendView) {
            FriendProfileView(userId: selectedFriend)
            
        }
        .onChange(of: displayFriendView) { newValue in
            selectedFriend = selectedFriend
        }
        
        
    }
}



func getPostFormattedDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    
    return dateFormatter.string(from: date)
}



struct FeedCell_Previews: PreviewProvider {
    static var previews: some View {
        FeedCell(post: postMockData, deletedPosts: .constant([]))
    }
}
