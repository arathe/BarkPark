//
//  DogPark.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import Foundation
import MapKit
import SwiftUI

struct DogPark: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let address: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
    let rules: String?
    let hoursOpen: String?
    let hoursClose: String?
    let createdAt: String
    let updatedAt: String
    
    // Activity properties (added by API responses)
    let activityLevel: String?
    let currentVisitors: Int?
    let distanceKm: Double?
    
    // NYC dog runs additional fields
    let website: String?
    let phone: String?
    let rating: Double?
    let reviewCount: Int?
    let surfaceType: String?
    let hasSeating: Bool?
    let zipcode: String?
    let borough: String?
    
    // Computed properties
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var activityLevelText: String {
        guard let level = activityLevel else { return "Unknown" }
        return level.capitalized
    }
    
    var activityColor: String {
        guard let level = activityLevel else { return "gray" }
        switch level.lowercased() {
        case "quiet":
            return "green"
        case "low":
            return "blue"
        case "moderate":
            return "orange"
        case "busy":
            return "red"
        default:
            return "gray"
        }
    }
    
    var activityColorSwiftUI: Color {
        guard let level = activityLevel else { return .gray }
        switch level.lowercased() {
        case "quiet":
            return .green
        case "low":
            return .blue
        case "moderate":
            return .orange
        case "busy":
            return .red
        default:
            return .gray
        }
    }
    
    var isOpen: Bool? {
        guard let openTime = hoursOpen, let closeTime = hoursClose else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        guard let open = formatter.date(from: openTime),
              let close = formatter.date(from: closeTime) else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let currentTime = calendar.dateComponents([.hour, .minute, .second], from: now)
        
        guard let currentDate = calendar.date(from: currentTime) else { return nil }
        
        if close < open {
            // Crosses midnight
            return currentDate >= open || currentDate <= close
        } else {
            return currentDate >= open && currentDate <= close
        }
    }
    
    var displayHours: String {
        guard let open = hoursOpen, let close = hoursClose else { return "Hours not available" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        
        guard let openTime = formatter.date(from: open),
              let closeTime = formatter.date(from: close) else {
            return "Hours not available"
        }
        
        return "\(displayFormatter.string(from: openTime)) - \(displayFormatter.string(from: closeTime))"
    }
    
    // Custom decoder to handle optional activity properties and snake_case fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        amenities = try container.decodeIfPresent([String].self, forKey: .amenities) ?? []
        rules = try container.decodeIfPresent(String.self, forKey: .rules)
        hoursOpen = try container.decodeIfPresent(String.self, forKey: .hoursOpen)
        hoursClose = try container.decodeIfPresent(String.self, forKey: .hoursClose) 
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        
        // Optional activity properties
        activityLevel = try container.decodeIfPresent(String.self, forKey: .activityLevel)
        currentVisitors = try container.decodeIfPresent(Int.self, forKey: .currentVisitors)
        distanceKm = try container.decodeIfPresent(Double.self, forKey: .distanceKm)
        
        // NYC dog runs additional fields
        website = try container.decodeIfPresent(String.self, forKey: .website)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        surfaceType = try container.decodeIfPresent(String.self, forKey: .surfaceType)
        hasSeating = try container.decodeIfPresent(Bool.self, forKey: .hasSeating)
        zipcode = try container.decodeIfPresent(String.self, forKey: .zipcode)
        borough = try container.decodeIfPresent(String.self, forKey: .borough)
    }
    
    // Convenience initializer for testing and previews
    init(
        id: Int,
        name: String,
        description: String?,
        address: String,
        latitude: Double,
        longitude: Double,
        amenities: [String],
        rules: String?,
        hoursOpen: String?,
        hoursClose: String?,
        createdAt: String,
        updatedAt: String,
        activityLevel: String? = nil,
        currentVisitors: Int? = nil,
        distanceKm: Double? = nil,
        website: String? = nil,
        phone: String? = nil,
        rating: Double? = nil,
        reviewCount: Int? = nil,
        surfaceType: String? = nil,
        hasSeating: Bool? = nil,
        zipcode: String? = nil,
        borough: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.amenities = amenities
        self.rules = rules
        self.hoursOpen = hoursOpen
        self.hoursClose = hoursClose
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.activityLevel = activityLevel
        self.currentVisitors = currentVisitors
        self.distanceKm = distanceKm
        self.website = website
        self.phone = phone
        self.rating = rating
        self.reviewCount = reviewCount
        self.surfaceType = surfaceType
        self.hasSeating = hasSeating
        self.zipcode = zipcode
        self.borough = borough
    }
    
    // Default Encodable implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(address, forKey: .address)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(amenities, forKey: .amenities)
        try container.encodeIfPresent(rules, forKey: .rules)
        try container.encodeIfPresent(hoursOpen, forKey: .hoursOpen)
        try container.encodeIfPresent(hoursClose, forKey: .hoursClose)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(activityLevel, forKey: .activityLevel)
        try container.encodeIfPresent(currentVisitors, forKey: .currentVisitors)
        try container.encodeIfPresent(distanceKm, forKey: .distanceKm)
        try container.encodeIfPresent(website, forKey: .website)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(reviewCount, forKey: .reviewCount)
        try container.encodeIfPresent(surfaceType, forKey: .surfaceType)
        try container.encodeIfPresent(hasSeating, forKey: .hasSeating)
        try container.encodeIfPresent(zipcode, forKey: .zipcode)
        try container.encodeIfPresent(borough, forKey: .borough)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude
        case amenities, rules, createdAt, updatedAt
        case hoursOpen, hoursClose  // Backend returns camelCase
        case activityLevel, currentVisitors
        case distanceKm = "distance_km"
        case website, phone, rating, reviewCount, surfaceType
        case hasSeating, zipcode, borough
    }
}

// MARK: - API Response Models
struct ParksSearchResponse: Codable {
    let parks: [DogPark]
    let total: Int
    let radius: Double?
    let center: SearchCenter?
    let query: String?
}

struct ParksResponse: Codable {
    let parks: [DogPark]
}

struct SearchCenter: Codable {
    let latitude: Double
    let longitude: Double
}

struct ParkDetailResponse: Codable {
    let park: ParkDetail
}

struct ParkDetail: Codable {
    let id: Int
    let name: String
    let description: String?
    let address: String
    let latitude: Double
    let longitude: Double
    let amenities: [String]
    let rules: String?
    let hoursOpen: String?
    let hoursClose: String?
    let activityLevel: String
    let stats: ParkStats
    let activeVisitors: Int
    let friendsPresent: Int
    let friends: [ParkFriend]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude
        case amenities, rules, activityLevel, stats, activeVisitors, friendsPresent, friends
        case hoursOpen = "hours_open"
        case hoursClose = "hours_close"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ParkStats: Codable {
    let totalCheckIns: Int
    let currentCheckIns: Int
    let averageVisitMinutes: Double?
}

struct ParkFriend: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let checkedInAt: String
    let dogs: [String]
}

struct ParkActivityResponse: Codable {
    let parkId: Int
    let activityLevel: String
    let stats: ParkStats
    let activeVisitors: [ActiveVisitor]
    let lastUpdated: String
}

struct ActiveVisitor: Codable {
    let userId: Int
    let firstName: String
    let lastName: String
    let checkedInAt: String
    let dogsPresent: [String]
}