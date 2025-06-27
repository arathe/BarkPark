import Foundation

@MainActor
class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    
    private let postId: Int
    private let apiService = APIService.shared
    private var currentOffset = 0
    private let limit = 20
    
    var currentUserId: Int {
        // Get from stored auth or app state
        UserDefaults.standard.integer(forKey: "user_id")
    }
    
    init(postId: Int) {
        self.postId = postId
    }
    
    func loadComments() {
        guard !isLoading else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let response = try await apiService.getComments(
                    postId: postId,
                    limit: limit,
                    offset: 0
                )
                
                comments = response.comments
                hasMore = response.comments.count >= limit
                currentOffset = response.comments.count
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    func loadMoreComments() {
        guard !isLoadingMore && hasMore else { return }
        
        Task {
            isLoadingMore = true
            
            do {
                let response = try await apiService.getComments(
                    postId: postId,
                    limit: limit,
                    offset: currentOffset
                )
                
                comments.append(contentsOf: response.comments)
                hasMore = response.comments.count >= limit
                currentOffset += response.comments.count
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoadingMore = false
        }
    }
    
    func postComment(content: String, parentCommentId: Int? = nil) {
        guard !isSending else { return }
        
        Task {
            isSending = true
            errorMessage = nil
            
            do {
                let newComment = try await apiService.postComment(
                    postId: postId,
                    content: content,
                    parentCommentId: parentCommentId
                )
                
                // Add the new comment to the appropriate place
                if let parentId = parentCommentId {
                    // Find parent comment and add as reply
                    addReplyToComment(parentId: parentId, reply: newComment)
                } else {
                    // Add as top-level comment at the beginning
                    let fullComment = Comment(
                        id: newComment.id,
                        postId: newComment.postId,
                        userId: newComment.userId,
                        content: newComment.content,
                        parentCommentId: newComment.parentCommentId,
                        createdAt: newComment.createdAt,
                        updatedAt: newComment.updatedAt,
                        user: CommentUser(
                            id: currentUserId,
                            firstName: UserDefaults.standard.string(forKey: "user_first_name") ?? "You",
                            lastName: UserDefaults.standard.string(forKey: "user_last_name") ?? "",
                            profileImageUrl: nil
                        ),
                        replies: []
                    )
                    comments.insert(fullComment, at: 0)
                }
                
                // Update comment count in feed
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentAdded"),
                    object: nil,
                    userInfo: ["postId": postId]
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isSending = false
        }
    }
    
    func deleteComment(_ comment: Comment) {
        Task {
            do {
                try await apiService.deleteComment(commentId: comment.id)
                
                // Remove from local state
                removeCommentFromTree(commentId: comment.id)
                
                // Update comment count in feed
                NotificationCenter.default.post(
                    name: NSNotification.Name("CommentDeleted"),
                    object: nil,
                    userInfo: ["postId": postId]
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func addReplyToComment(parentId: Int, reply: CommentResponse) {
        func addReplyRecursive(to comments: inout [Comment]) -> Bool {
            for i in 0..<comments.count {
                if comments[i].id == parentId {
                    let fullReply = Comment(
                        id: reply.id,
                        postId: reply.postId,
                        userId: reply.userId,
                        content: reply.content,
                        parentCommentId: reply.parentCommentId,
                        createdAt: reply.createdAt,
                        updatedAt: reply.updatedAt,
                        user: CommentUser(
                            id: currentUserId,
                            firstName: UserDefaults.standard.string(forKey: "user_first_name") ?? "You",
                            lastName: UserDefaults.standard.string(forKey: "user_last_name") ?? "",
                            profileImageUrl: nil
                        ),
                        replies: []
                    )
                    comments[i].replies.append(fullReply)
                    return true
                } else if addReplyRecursive(to: &comments[i].replies) {
                    return true
                }
            }
            return false
        }
        
        _ = addReplyRecursive(to: &comments)
    }
    
    private func removeCommentFromTree(commentId: Int) {
        func removeRecursive(from comments: inout [Comment]) -> Bool {
            if let index = comments.firstIndex(where: { $0.id == commentId }) {
                comments.remove(at: index)
                return true
            }
            
            for i in 0..<comments.count {
                if removeRecursive(from: &comments[i].replies) {
                    return true
                }
            }
            return false
        }
        
        _ = removeRecursive(from: &comments)
    }
}