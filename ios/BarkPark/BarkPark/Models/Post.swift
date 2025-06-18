import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    let userId: Int
    let content: String?
    let postType: PostType
    let visibility: PostVisibility
    let checkInId: Int?
    let sharedPostId: Int?
    let createdAt: Date
    let updatedAt: Date
    
    // User info
    let firstName: String
    let lastName: String
    let userProfileImage: String?
    
    // Engagement counts
    let likeCount: Int
    let commentCount: Int
    let userLiked: Bool?
    
    // Media attachments
    let media: [PostMedia]?
    
    // Check-in info
    let checkIn: CheckInInfo?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    enum CodingKeys: String, CodingKey {
        case id, content, visibility, media
        case userId = "user_id"
        case postType = "post_type"
        case checkInId = "check_in_id"
        case sharedPostId = "shared_post_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case userProfileImage = "user_profile_image"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case userLiked = "user_liked"
        case checkIn = "check_in"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum PostType: String, Codable {
    case status = "status"
    case checkin = "checkin"
    case media = "media"
    case shared = "shared"
}

enum PostVisibility: String, Codable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
}

struct PostMedia: Codable, Identifiable {
    let id: Int
    let mediaType: MediaType
    let mediaUrl: String
    let thumbnailUrl: String?
    let width: Int?
    let height: Int?
    let duration: Int?
    let orderIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, duration
        case mediaType = "media_type"
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case orderIndex = "order_index"
    }
}

enum MediaType: String, Codable {
    case photo = "photo"
    case video = "video"
}

struct CheckInInfo: Codable {
    let id: Int
    let parkId: Int
    let parkName: String
    let checkedInAt: String // Keep as String for now since we're having date issues
    
    enum CodingKeys: String, CodingKey {
        case id
        case parkId = "park_id"
        case parkName = "park_name"
        case checkedInAt = "checked_in_at"
    }
}

// Create Post Request
struct CreatePostRequest: Codable {
    let content: String?
    let postType: PostType
    let visibility: PostVisibility
    let checkInId: Int?
    let sharedPostId: Int?
    
    enum CodingKeys: String, CodingKey {
        case content, visibility
        case postType = "post_type"
        case checkInId = "check_in_id"
        case sharedPostId = "shared_post_id"
    }
}

// Feed Response
struct FeedResponse: Codable {
    let posts: [Post]
    let pagination: Pagination
}

struct Pagination: Codable {
    let limit: Int
    let offset: Int
    let hasMore: Bool
}