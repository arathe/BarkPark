import Foundation

struct Comment: Identifiable, Codable {
    let id: Int
    let postId: Int
    let userId: Int
    let content: String
    let parentCommentId: Int?
    let createdAt: Date
    let updatedAt: Date
    
    // Nested user information
    let user: CommentUser
    
    // Nested replies (populated by backend)
    var replies: [Comment]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case parentCommentId = "parent_comment_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case replies
    }
    
    // Computed properties
    var isReply: Bool {
        parentCommentId != nil
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var hasReplies: Bool {
        !replies.isEmpty
    }
}

struct CommentUser: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let profileImageUrl: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case profileImageUrl = "profile_image_url"
    }
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

// Response structures
struct CommentsResponse: Codable {
    let comments: [Comment]
    let total: Int
}

struct CommentResponse: Codable {
    let id: Int
    let postId: Int
    let userId: Int
    let content: String
    let parentCommentId: Int?
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case parentCommentId = "parent_comment_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DeleteCommentResponse: Codable {
    let message: String
}