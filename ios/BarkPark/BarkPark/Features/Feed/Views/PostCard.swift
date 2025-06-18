import SwiftUI

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            // Header
            HStack {
                AsyncImage(url: URL(string: post.userProfileImage ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.fullName)
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    HStack(spacing: BarkParkDesign.Spacing.xs) {
                        Text(post.timeAgo)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        if post.visibility != .public {
                            Image(systemName: post.visibility == .friends ? "person.2.fill" : "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Menu {
                    Button("Share", action: {})
                    if post.userId == UserDefaults.standard.integer(forKey: "user_id") {
                        Button("Delete", role: .destructive, action: {})
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
            }
            
            // Check-in info
            if let checkIn = post.checkIn {
                HStack(spacing: BarkParkDesign.Spacing.xs) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(BarkParkDesign.Colors.dogSecondary)
                    
                    Text("Checked in at \(checkIn.parkName)")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.dogSecondary)
                }
                .padding(.vertical, 2)
            }
            
            // Content
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Media
            if let media = post.media, !media.isEmpty {
                MediaGalleryView(media: media)
                    .padding(.vertical, BarkParkDesign.Spacing.xs)
            }
            
            // Engagement stats
            HStack {
                if post.likeCount > 0 {
                    Text("\(post.likeCount) \(post.likeCount == 1 ? "like" : "likes")")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                
                Spacer()
                
                if post.commentCount > 0 {
                    Button(action: { showComments = true }) {
                        Text("\(post.commentCount) \(post.commentCount == 1 ? "comment" : "comments")")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
            }
            .padding(.vertical, BarkParkDesign.Spacing.xs)
            
            // Action buttons
            HStack(spacing: 0) {
                Button(action: onLike) {
                    HStack(spacing: BarkParkDesign.Spacing.xs) {
                        Image(systemName: post.userLiked ?? false ? "heart.fill" : "heart")
                            .foregroundColor(post.userLiked ?? false ? .red : BarkParkDesign.Colors.secondaryText)
                        Text("Like")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    .font(BarkParkDesign.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                }
                
                Button(action: { showComments = true }) {
                    HStack(spacing: BarkParkDesign.Spacing.xs) {
                        Image(systemName: "bubble.left")
                        Text("Comment")
                    }
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .font(BarkParkDesign.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                }
                
                Button(action: {}) {
                    HStack(spacing: BarkParkDesign.Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .font(BarkParkDesign.Typography.body)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                }
            }
        }
        .sheet(isPresented: $showComments) {
            // TODO: CommentsView
            Text("Comments")
        }
    }
}

struct MediaGalleryView: View {
    let media: [PostMedia]
    
    var body: some View {
        if media.count == 1 {
            SingleMediaView(media: media[0])
        } else if media.count == 2 {
            HStack(spacing: 2) {
                ForEach(media.prefix(2)) { item in
                    SingleMediaView(media: item)
                }
            }
            .aspectRatio(2, contentMode: .fit)
        } else if media.count == 3 {
            HStack(spacing: 2) {
                SingleMediaView(media: media[0])
                VStack(spacing: 2) {
                    SingleMediaView(media: media[1])
                    SingleMediaView(media: media[2])
                }
            }
            .aspectRatio(1.5, contentMode: .fit)
        } else {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                ForEach(media.prefix(4)) { item in
                    SingleMediaView(media: item)
                        .overlay(
                            media.count > 4 && item.id == media[3].id ?
                            Color.black.opacity(0.5)
                                .overlay(
                                    Text("+\(media.count - 4)")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                            : nil
                        )
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

struct SingleMediaView: View {
    let media: PostMedia
    
    var body: some View {
        AsyncImage(url: URL(string: media.thumbnailUrl ?? media.mediaUrl)) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .foregroundColor(Color(.systemGray5))
                .overlay(
                    ProgressView()
                )
        }
        .clipped()
        .overlay(
            media.mediaType == .video ?
            Image(systemName: "play.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .shadow(radius: 3)
            : nil
        )
    }
}