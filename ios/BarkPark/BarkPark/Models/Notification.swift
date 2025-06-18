import Foundation

struct Notification: Codable, Identifiable {
    let id: Int
    let userId: Int
    let type: NotificationType
    let actorId: Int
    let postId: Int?
    let commentId: Int?
    let isRead: Bool
    let createdAt: Date
    
    // Actor info
    let actorFirstName: String
    let actorLastName: String
    let actorProfileImage: String?
    
    // Post info
    let postContent: String?
    let postType: String?
    let postMedia: [PostMediaPreview]?
    
    // Comment info
    let commentContent: String?
    
    // Formatted text
    let text: String
    
    var actorFullName: String {
        "\(actorFirstName) \(actorLastName)"
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, text
        case userId = "user_id"
        case actorId = "actor_id"
        case postId = "post_id"
        case commentId = "comment_id"
        case isRead = "is_read"
        case createdAt = "created_at"
        case actorFirstName = "actor_first_name"
        case actorLastName = "actor_last_name"
        case actorProfileImage = "actor_profile_image"
        case postContent = "post_content"
        case postType = "post_type"
        case postMedia = "post_media"
        case commentContent = "comment_content"
    }
}

enum NotificationType: String, Codable {
    case like = "like"
    case comment = "comment"
    case mention = "mention"
    case friendCheckin = "friend_checkin"
    case friendPost = "friend_post"
}

struct PostMediaPreview: Codable {
    let mediaType: String
    let mediaUrl: String
    let thumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
    }
}

struct NotificationsResponse: Codable {
    let notifications: [Notification]
    let unreadCount: Int
    let pagination: Pagination
}