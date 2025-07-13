import Foundation
import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    @Published var isRefreshing = false
    
    private let apiService = APIService.shared
    private var currentOffset = 0
    private let pageSize = 20
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentAdded),
            name: NSNotification.Name("CommentAdded"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCommentDeleted),
            name: NSNotification.Name("CommentDeleted"),
            object: nil
        )
    }
    
    @objc private func handleCommentAdded(_ notification: Foundation.Notification) {
        guard let postId = notification.userInfo?["postId"] as? Int else { return }
        updateCommentCount(for: postId, increment: 1)
    }
    
    @objc private func handleCommentDeleted(_ notification: Foundation.Notification) {
        guard let postId = notification.userInfo?["postId"] as? Int else { return }
        updateCommentCount(for: postId, increment: -1)
    }
    
    private func updateCommentCount(for postId: Int, increment: Int) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            let updatedPost = posts[index]
            var updatedPosts = posts
            
            updatedPosts[index] = Post(
                id: updatedPost.id,
                userId: updatedPost.userId,
                content: updatedPost.content,
                postType: updatedPost.postType,
                visibility: updatedPost.visibility,
                checkInId: updatedPost.checkInId,
                sharedPostId: updatedPost.sharedPostId,
                createdAt: updatedPost.createdAt,
                updatedAt: updatedPost.updatedAt,
                firstName: updatedPost.firstName,
                lastName: updatedPost.lastName,
                userProfileImage: updatedPost.userProfileImage,
                likeCount: updatedPost.likeCount,
                commentCount: max(0, updatedPost.commentCount + increment),
                userLiked: updatedPost.userLiked,
                media: updatedPost.media,
                checkIn: updatedPost.checkIn
            )
            posts = updatedPosts
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getFeed(limit: pageSize, offset: 0)
            posts = response.posts
            hasMore = response.pagination.hasMore
            currentOffset = response.posts.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        do {
            let response = try await apiService.getFeed(limit: pageSize, offset: currentOffset)
            posts.append(contentsOf: response.posts)
            hasMore = response.pagination.hasMore
            currentOffset = posts.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() async {
        isRefreshing = true
        currentOffset = 0
        
        do {
            let response = try await apiService.getFeed(limit: pageSize, offset: 0)
            posts = response.posts
            hasMore = response.pagination.hasMore
            currentOffset = response.posts.count
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
    }
    
    func toggleLike(for post: Post) async {
        // Optimistically update UI
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            var updatedPost = posts[index]
            let wasLiked = updatedPost.userLiked ?? false
            
            // Create a mutable copy with updated values
            var updatedPosts = posts
            updatedPosts[index] = Post(
                id: updatedPost.id,
                userId: updatedPost.userId,
                content: updatedPost.content,
                postType: updatedPost.postType,
                visibility: updatedPost.visibility,
                checkInId: updatedPost.checkInId,
                sharedPostId: updatedPost.sharedPostId,
                createdAt: updatedPost.createdAt,
                updatedAt: updatedPost.updatedAt,
                firstName: updatedPost.firstName,
                lastName: updatedPost.lastName,
                userProfileImage: updatedPost.userProfileImage,
                likeCount: wasLiked ? updatedPost.likeCount - 1 : updatedPost.likeCount + 1,
                commentCount: updatedPost.commentCount,
                userLiked: !wasLiked,
                media: updatedPost.media,
                checkIn: updatedPost.checkIn
            )
            posts = updatedPosts
            
            // Make API call
            do {
                let liked = try await apiService.likePost(postId: post.id)
                // If API returns different result, update again
                if liked != !wasLiked {
                    await loadFeed() // Reload to get accurate data
                }
            } catch {
                // Revert on error
                posts = posts // Trigger update
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func deletePost(_ post: Post) async {
        // TODO: Implement delete functionality
    }
}
