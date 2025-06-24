//
//  CheckIn.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import Foundation

struct CheckIn: Codable, Identifiable, Equatable {
    let id: Int
    let userId: Int
    let dogParkId: Int
    let checkedInAt: String
    let checkedOutAt: String?
    let dogsPresent: [Int]
    let createdAt: String?
    let updatedAt: String?
    
    // Park information (included in some API responses)
    let park: CheckInPark?
    
    // Computed properties
    var isActive: Bool {
        return checkedOutAt == nil
    }
    
    var visitDuration: TimeInterval? {
        let formatter = ISO8601DateFormatter()
        
        guard let checkedIn = formatter.date(from: checkedInAt) else { return nil }
        
        if let checkedOutTime = checkedOutAt,
           let checkedOut = formatter.date(from: checkedOutTime) {
            return checkedOut.timeIntervalSince(checkedIn)
        } else if isActive {
            return Date().timeIntervalSince(checkedIn)
        }
        
        return nil
    }
    
    var visitDurationText: String {
        guard let duration = visitDuration else { return "Unknown" }
        
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var checkedInTimeText: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: checkedInAt) else { return checkedInAt }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, userId, dogParkId, checkedInAt, checkedOutAt, dogsPresent, createdAt, updatedAt, park
    }
}

struct CheckInPark: Codable, Equatable {
    let id: Int
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

// MARK: - Check-in Request Models
struct CheckInRequest: Codable {
    let dogsPresent: [Int]
}

// MARK: - API Response Models
struct CheckInResponse: Codable {
    let message: String
    let checkIn: CheckIn
    let park: DogPark
    let post: Post?
}

struct CheckOutResponse: Codable {
    let message: String
    let checkOut: CheckIn
    let park: DogPark
}

struct CheckInHistoryResponse: Codable {
    let history: [CheckInHistory]
    let total: Int
}

struct CheckInHistory: Codable, Identifiable {
    let id: Int
    let userId: Int
    let dogParkId: Int
    let checkedInAt: String
    let checkedOutAt: String?
    let dogsPresent: [Int]
    let visitDurationMinutes: Int?
    let park: CheckInPark
    
    var visitDurationText: String {
        guard let minutes = visitDurationMinutes else { return "In progress" }
        
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var checkedInTimeText: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: checkedInAt) else { return checkedInAt }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        
        return displayFormatter.string(from: date)
    }
}

struct ActiveCheckInsResponse: Codable {
    let activeCheckIns: [CheckIn]
    let total: Int
}

struct FriendsAtParkResponse: Codable {
    let parkId: Int
    let friendsPresent: Int
    let friends: [ParkFriend]
}