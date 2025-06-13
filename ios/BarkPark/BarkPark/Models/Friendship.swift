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