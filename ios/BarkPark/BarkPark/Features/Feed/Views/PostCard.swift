import SwiftUI

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    
    @State private var showComments = false
    @State private var isLikeAnimating = false
    @State private var showMenu = false
    @State private var contentExpanded = false
    
    private let maxContentLength = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Content
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                // Header
                headerView
                
                // Check-in Badge
                if let checkIn = post.checkIn {
                    checkInBadge(checkIn)
                }
                
                // Content
                if let content = post.content, !content.isEmpty {
                    contentView(content)
                }
                
                // Media
                if let media = post.media, !media.isEmpty {
                    MediaGalleryView(media: media)
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large))
                        .padding(.top, BarkParkDesign.Spacing.xs)
                }
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                
                // Actions
                actionBar
            }
            .padding(BarkParkDesign.Spacing.md)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.extraLarge))
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 10,
            x: 0,
            y: 2
        )
        .sheet(isPresented: $showComments) {
            CommentsView(post: post)
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top, spacing: BarkParkDesign.Spacing.sm) {
            // Profile Image
            AsyncImage(url: URL(string: post.userProfileImage ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                BarkParkDesign.Colors.dogPrimary.opacity(0.3),
                                BarkParkDesign.Colors.dogSecondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(post.fullName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    if post.postType == .checkin {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(post.timeAgo)
                        .font(.system(size: 14))
                        .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                    
                    if post.visibility != .public {
                        Circle()
                            .fill(BarkParkDesign.Colors.tertiaryText)
                            .frame(width: 3, height: 3)
                        
                        HStack(spacing: 4) {
                            Image(systemName: post.visibility == .friends ? "person.2.fill" : "lock.fill")
                                .font(.system(size: 11))
                            
                            Text(post.visibility == .friends ? "Friends" : "Private")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                    }
                }
            }
            
            Spacer()
            
            // Menu Button
            Menu {
                Button(action: {}) {
                    Label("Share Post", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {}) {
                    Label("Copy Link", systemImage: "link")
                }
                
                if post.userId == UserDefaults.standard.integer(forKey: "user_id") {
                    Divider()
                    
                    Button(role: .destructive, action: {}) {
                        Label("Delete Post", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.08))
                    )
            }
        }
    }
    
    private func checkInBadge(_ checkIn: CheckInInfo) -> some View {
        HStack(spacing: BarkParkDesign.Spacing.sm) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text(checkIn.parkName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, BarkParkDesign.Spacing.md)
        .padding(.vertical, BarkParkDesign.Spacing.sm)
        .background(
            LinearGradient(
                colors: [
                    BarkParkDesign.Colors.dogPrimary,
                    BarkParkDesign.Colors.dogPrimary.opacity(0.8)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
    }
    
    private func contentView(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
            Text(content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(BarkParkDesign.Colors.primaryText)
                .lineLimit(contentExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)
            
            if content.count > maxContentLength && !contentExpanded {
                Button(action: { 
                    withAnimation(BarkParkDesign.Animation.spring) {
                        contentExpanded = true
                    }
                }) {
                    Text("Read more")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
            }
        }
    }
    
    private var actionBar: some View {
        HStack(spacing: 0) {
            // Like Button
            Button(action: {
                withAnimation(BarkParkDesign.Animation.bouncy) {
                    isLikeAnimating = true
                }
                onLike()
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isLikeAnimating = false
                }
            }) {
                HStack(spacing: BarkParkDesign.Spacing.xs) {
                    Image(systemName: post.userLiked ?? false ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(post.userLiked ?? false ? .red : BarkParkDesign.Colors.secondaryText)
                        .scaleEffect(isLikeAnimating ? 1.3 : 1.0)
                        .animation(BarkParkDesign.Animation.bouncy, value: isLikeAnimating)
                    
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                .padding(.vertical, BarkParkDesign.Spacing.sm)
                .padding(.horizontal, BarkParkDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                        .fill((post.userLiked ?? false) ? Color.red.opacity(0.1) : Color.gray.opacity(0.08))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // Comment Button
            Button(action: { showComments = true }) {
                HStack(spacing: BarkParkDesign.Spacing.xs) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 20))
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                .padding(.vertical, BarkParkDesign.Spacing.sm)
                .padding(.horizontal, BarkParkDesign.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                        .fill(Color.gray.opacity(0.08))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // Share Button
            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(.system(size: 20))
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                    .padding(.horizontal, BarkParkDesign.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                            .fill(Color.gray.opacity(0.08))
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// Custom button style for subtle press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(BarkParkDesign.Animation.quick, value: configuration.isPressed)
    }
}

// Placeholder for comments view
struct CommentsView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Comments for post")
                    .font(BarkParkDesign.Typography.headline)
                
                Spacer()
                
                Text("Comments feature coming soon!")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                
                Spacer()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            PostCard(
                post: Post(
                    id: 1,
                    userId: 1,
                    content: "Just had an amazing time at the dog park! 🐕 My pup made so many new friends today. The weather was perfect and everyone was so friendly. Can't wait to come back tomorrow!",
                    postType: .status,
                    visibility: .friends,
                    checkInId: nil,
                    sharedPostId: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    firstName: "John",
                    lastName: "Doe",
                    userProfileImage: nil,
                    likeCount: 12,
                    commentCount: 3,
                    userLiked: true,
                    media: nil,
                    checkIn: nil
                ),
                onLike: {}
            )
            
            PostCard(
                post: Post(
                    id: 2,
                    userId: 2,
                    content: "Checked in at Central Park Dog Run!",
                    postType: .checkin,
                    visibility: .public,
                    checkInId: 1,
                    sharedPostId: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    firstName: "Jane",
                    lastName: "Smith",
                    userProfileImage: nil,
                    likeCount: 5,
                    commentCount: 0,
                    userLiked: false,
                    media: nil,
                    checkIn: CheckInInfo(
                        id: 1,
                        parkId: 1,
                        parkName: "Central Park Dog Run",
                        checkedInAt: "2025-06-18T09:00:00Z"
                    )
                ),
                onLike: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}