//
//  Friendship.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import Foundation

// MARK: - Friendship Status
enum FriendshipStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Friends"
        case .declined:
            return "Declined"
        }
    }
}

// MARK: - Friend Request Type
enum FriendRequestType: String, Codable {
    case sent = "sent"
    case received = "received"
    
    var displayName: String {
        switch self {
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        }
    }
}

// MARK: - Friendship Model
struct Friendship: Codable, Identifiable {
    let id: Int
    let requesterId: Int
    let addresseeId: Int
    let status: FriendshipStatus
    let createdAt: String
    let updatedAt: String?
    let isRequester: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requesterId"
        case addresseeId = "addresseeId"
        case status
        case createdAt
        case updatedAt
        case isRequester
    }
    
    // Support legacy snake_case keys from older backend responses
    enum LegacyKeys: String, CodingKey {
        case user_id
        case friend_id
        case requester_id
        case addressee_id
        case created_at
        case updated_at
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try? decoder.container(keyedBy: LegacyKeys.self)
        
        self.id = try container.decodeIfPresent(Int.self, forKey: .id)
            ?? 0
        
        if let requester = try container.decodeIfPresent(Int.self, forKey: .requesterId) {
            self.requesterId = requester
        } else if let legacyRequester = try legacy?.decodeIfPresent(Int.self, forKey: .user_id) {
            self.requesterId = legacyRequester
        } else if let legacyRequester2 = try legacy?.decodeIfPresent(Int.self, forKey: .requester_id) {
            self.requesterId = legacyRequester2
        } else {
            throw DecodingError.keyNotFound(CodingKeys.requesterId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing requesterId/user_id"))
        }
        
        if let addressee = try container.decodeIfPresent(Int.self, forKey: .addresseeId) {
            self.addresseeId = addressee
        } else if let legacyAddressee = try legacy?.decodeIfPresent(Int.self, forKey: .friend_id) {
            self.addresseeId = legacyAddressee
        } else if let legacyAddressee2 = try legacy?.decodeIfPresent(Int.self, forKey: .addressee_id) {
            self.addresseeId = legacyAddressee2
        } else {
            throw DecodingError.keyNotFound(CodingKeys.addresseeId, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing addresseeId/friend_id"))
        }
        
        self.status = try container.decode(FriendshipStatus.self, forKey: .status)
        
        if let created = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            self.createdAt = created
        } else if let legacyCreated = try legacy?.decodeIfPresent(String.self, forKey: .created_at) {
            self.createdAt = legacyCreated
        } else {
            throw DecodingError.keyNotFound(CodingKeys.createdAt, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Missing createdAt/created_at"))
        }
        
        if let updated = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            self.updatedAt = updated
        } else if let legacyUpdated = try legacy?.decodeIfPresent(String.self, forKey: .updated_at) {
            self.updatedAt = legacyUpdated
        } else {
            self.updatedAt = nil
        }
        
        self.isRequester = try container.decodeIfPresent(Bool.self, forKey: .isRequester)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return createdAt
    }
}

// MARK: - Friend Data Model
struct Friend: Codable, Identifiable {
    let friendshipId: Int
    let status: FriendshipStatus
    let friendshipCreatedAt: String
    let friend: User
    
    var id: Int { friend.id }
    
    enum CodingKeys: String, CodingKey {
        case friendshipId
        case status
        case friendshipCreatedAt
        case friend
    }
}

// MARK: - Friend Request Model
struct FriendRequest: Codable, Identifiable {
    let friendshipId: Int
    let status: FriendshipStatus
    let createdAt: String
    let requestType: FriendRequestType
    let otherUser: User
    
    var id: Int { friendshipId }
    
    enum CodingKeys: String, CodingKey {
        case friendshipId
        case status
        case createdAt
        case requestType
        case otherUser
    }
    
    var actionText: String {
        switch requestType {
        case .sent:
            return "Friend request sent"
        case .received:
            return "Friend request received"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: createdAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return createdAt
    }
}

// MARK: - API Response Models
struct SendFriendRequestResponse: Codable {
    let message: String
    let friendship: Friendship
}

struct FriendRequestActionResponse: Codable {
    let message: String
    let friendship: Friendship
}

struct FriendsListResponse: Codable {
    let message: String
    let friends: [Friend]
}

struct FriendRequestsResponse: Codable {
    let message: String
    let requests: [FriendRequest]
}

struct UserSearchResponse: Codable {
    let message: String
    let users: [User]
    let count: Int
}

struct FriendshipStatusResponse: Codable {
    let friendship: Friendship?
}

struct RemoveFriendResponse: Codable {
    let success: Bool
    let message: String
}

struct QRConnectResponse: Codable {
    let message: String
    let friendship: Friendship
    let targetUser: User
}
