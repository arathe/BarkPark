//
//  Dog.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation

struct Dog: Codable, Identifiable {
    let id: Int
    let name: String
    let breed: String?
    let birthday: String?
    let age: Int?
    let weight: Double?
    let gender: String
    let sizeCategory: String
    let energyLevel: String
    let friendlinessDogs: Int
    let friendlinessPeople: Int
    let trainingLevel: String
    let favoriteActivities: [String]
    let isVaccinated: Bool
    let isSpayedNeutered: Bool
    let specialNeeds: String?
    let bio: String?
    let profileImageUrl: String?
    let galleryImages: [String]
    let owners: [DogOwnerSummary]
    let currentUserRole: DogOwnershipRole?
    let createdAt: String
    let updatedAt: String
    
    // Custom decoder to handle weight as string or double
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        breed = try container.decodeIfPresent(String.self, forKey: .breed)
        birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        
        // Handle weight as either Double or String
        if let weightDouble = try? container.decodeIfPresent(Double.self, forKey: .weight) {
            weight = weightDouble
        } else if let weightString = try? container.decodeIfPresent(String.self, forKey: .weight),
                  let weightValue = Double(weightString) {
            weight = weightValue
        } else {
            weight = nil
        }
        
        gender = try container.decode(String.self, forKey: .gender)
        sizeCategory = try container.decode(String.self, forKey: .sizeCategory)
        energyLevel = try container.decode(String.self, forKey: .energyLevel)
        friendlinessDogs = try container.decode(Int.self, forKey: .friendlinessDogs)
        friendlinessPeople = try container.decode(Int.self, forKey: .friendlinessPeople)
        trainingLevel = try container.decode(String.self, forKey: .trainingLevel)
        favoriteActivities = try container.decode([String].self, forKey: .favoriteActivities)
        isVaccinated = try container.decode(Bool.self, forKey: .isVaccinated)
        isSpayedNeutered = try container.decode(Bool.self, forKey: .isSpayedNeutered)
        specialNeeds = try container.decodeIfPresent(String.self, forKey: .specialNeeds)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        galleryImages = try container.decodeIfPresent([String].self, forKey: .galleryImages) ?? []

        if let decodedOwners = try container.decodeIfPresent([DogOwnerSummary].self, forKey: .owners) {
            owners = decodedOwners
        } else if let decodedOwners = try container.decodeIfPresent([DogOwnerSummary].self, forKey: .ownerSummaries) {
            owners = decodedOwners
        } else {
            owners = []
        }

        if let role = try container.decodeIfPresent(DogOwnershipRole.self, forKey: .currentUserRole) {
            currentUserRole = role
        } else if let role = try container.decodeIfPresent(DogOwnershipRole.self, forKey: .currentUserRoleSnake) {
            currentUserRole = role
        } else {
            currentUserRole = nil
        }
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(breed, forKey: .breed)
        try container.encodeIfPresent(birthday, forKey: .birthday)
        try container.encodeIfPresent(age, forKey: .age)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encode(gender, forKey: .gender)
        try container.encode(sizeCategory, forKey: .sizeCategory)
        try container.encode(energyLevel, forKey: .energyLevel)
        try container.encode(friendlinessDogs, forKey: .friendlinessDogs)
        try container.encode(friendlinessPeople, forKey: .friendlinessPeople)
        try container.encode(trainingLevel, forKey: .trainingLevel)
        try container.encode(favoriteActivities, forKey: .favoriteActivities)
        try container.encode(isVaccinated, forKey: .isVaccinated)
        try container.encode(isSpayedNeutered, forKey: .isSpayedNeutered)
        try container.encodeIfPresent(specialNeeds, forKey: .specialNeeds)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(galleryImages, forKey: .galleryImages)
        try container.encode(owners, forKey: .owners)
        try container.encodeIfPresent(currentUserRole, forKey: .currentUserRole)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    // CodingKeys for custom decoder
    private enum CodingKeys: String, CodingKey {
        case id, name, breed, birthday, age, weight, gender
        case sizeCategory, energyLevel, friendlinessDogs, friendlinessPeople
        case trainingLevel, favoriteActivities, isVaccinated, isSpayedNeutered
        case specialNeeds, bio, profileImageUrl, galleryImages, owners
        case createdAt, updatedAt
        case currentUserRole
        case ownerSummaries = "owner_summaries"
        case currentUserRoleSnake = "current_user_role"
    }

    // Computed properties
    var computedAge: Int {
        // Use backend-provided age if available, otherwise compute it
        if let age = age { return age }
        
        guard let birthday = birthday else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let birthDate = formatter.date(from: birthday) else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    var displayGender: String {
        switch gender.lowercased() {
        case "male":
            return "Male"
        case "female":
            return "Female"
        default:
            return gender.capitalized
        }
    }
    
    var displaySize: String {
        switch sizeCategory.lowercased() {
        case "small":
            return "Small"
        case "medium":
            return "Medium"
        case "large":
            return "Large"
        case "extra_large":
            return "Extra Large"
        default:
            return sizeCategory.capitalized
        }
    }
    
    var displayEnergyLevel: String {
        switch energyLevel.lowercased() {
        case "low":
            return "Low Energy"
        case "medium":
            return "Medium Energy"
        case "high":
            return "High Energy"
        default:
            return energyLevel.capitalized
        }
    }
    
    var displayTrainingLevel: String {
        switch trainingLevel.lowercased() {
        case "puppy":
            return "Puppy"
        case "basic":
            return "Basic Training"
        case "advanced":
            return "Advanced"
        default:
            return trainingLevel.capitalized
        }
    }

    var activeOwners: [DogOwnerSummary] {
        owners.filter { !$0.isPending }
    }

    func ownerSummary(for userId: Int) -> DogOwnerSummary? {
        owners.first { $0.id == userId }
    }
}

// MARK: - Ownership Models

struct DogOwnerSummary: Codable, Identifiable, Hashable {
    let id: Int
    let membershipId: Int?
    let firstName: String
    let lastName: String
    let displayName: String?
    let profileImageUrl: String?
    let role: DogOwnershipRole
    let status: DogMembershipStatus

    init(
        id: Int,
        membershipId: Int?,
        firstName: String,
        lastName: String,
        displayName: String?,
        profileImageUrl: String?,
        role: DogOwnershipRole,
        status: DogMembershipStatus
    ) {
        self.id = id
        self.membershipId = membershipId
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.profileImageUrl = profileImageUrl
        self.role = role
        self.status = status
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case membershipId
        case firstName
        case lastName
        case displayName
        case profileImageUrl
        case role
        case status
        case membershipIdSnake = "membership_id"
        case firstNameSnake = "first_name"
        case lastNameSnake = "last_name"
        case displayNameSnake = "display_name"
        case profileImageUrlSnake = "profile_image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        membershipId = try container.decodeIfPresent(Int.self, forKey: .membershipId) ??
            container.decodeIfPresent(Int.self, forKey: .membershipIdSnake)

        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ??
            container.decodeIfPresent(String.self, forKey: .firstNameSnake) ?? ""
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ??
            container.decodeIfPresent(String.self, forKey: .lastNameSnake) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ??
            container.decodeIfPresent(String.self, forKey: .displayNameSnake)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl) ??
            container.decodeIfPresent(String.self, forKey: .profileImageUrlSnake)
        role = (try? container.decode(DogOwnershipRole.self, forKey: .role)) ?? .unknown
        status = (try? container.decode(DogMembershipStatus.self, forKey: .status)) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(membershipId, forKey: .membershipId)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(profileImageUrl, forKey: .profileImageUrl)
        try container.encode(role, forKey: .role)
        try container.encode(status, forKey: .status)
    }

    var fullName: String {
        if let displayName, !displayName.isEmpty {
            return displayName
        }
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Unknown User" : combined
    }

    var initials: String {
        let components = [firstName.first, lastName.first].compactMap { $0 }
        if components.isEmpty {
            return String(fullName.prefix(1)).uppercased()
        }
        return components.map { String($0) }.joined().uppercased()
    }

    var statusBadgeText: String? {
        switch status {
        case .invited, .pending, .requested:
            return "Pending"
        case .declined:
            return "Declined"
        default:
            return nil
        }
    }

    var isPending: Bool {
        status.isPending
    }

    var displayRole: String {
        role.displayName
    }
}

enum DogOwnershipRole: String, Codable, CaseIterable {
    case owner = "owner"
    case coOwner = "co_owner"
    case caretaker = "caretaker"
    case viewer = "viewer"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = DogOwnershipRole(rawValue: rawValue) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if self == .unknown {
            try container.encode("unknown")
        } else {
            try container.encode(rawValue)
        }
    }

    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .coOwner:
            return "Co-Owner"
        case .caretaker:
            return "Caretaker"
        case .viewer:
            return "Viewer"
        case .unknown:
            return "Shared"
        }
    }

    var canEditProfile: Bool {
        switch self {
        case .owner, .coOwner, .caretaker:
            return true
        default:
            return false
        }
    }

    var canDeleteProfile: Bool {
        switch self {
        case .owner, .coOwner:
            return true
        default:
            return false
        }
    }

    var canManageMembers: Bool {
        switch self {
        case .owner, .coOwner:
            return true
        default:
            return false
        }
    }

    var isPending: Bool {
        false
    }
}

enum DogMembershipStatus: String, Codable {
    case active = "active"
    case invited = "invited"
    case pending = "pending"
    case requested = "requested"
    case declined = "declined"
    case removed = "removed"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = DogMembershipStatus(rawValue: rawValue) ?? .unknown
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if self == .unknown {
            try container.encode("unknown")
        } else {
            try container.encode(rawValue)
        }
    }

    var isPending: Bool {
        switch self {
        case .invited, .pending, .requested:
            return true
        default:
            return false
        }
    }
}

// MARK: - Dog Creation Request
struct CreateDogRequest: Codable {
    let name: String
    let breed: String
    let birthday: String
    let weight: Double?
    let gender: String
    let sizeCategory: String
    let energyLevel: String
    let friendlinessDogs: Int
    let friendlinessPeople: Int
    let trainingLevel: String
    let favoriteActivities: [String]
    let isVaccinated: Bool
    let isSpayedNeutered: Bool
    let specialNeeds: String?
    let bio: String?
}

// MARK: - Dog Update Request
struct UpdateDogRequest: Codable {
    let name: String
    let breed: String
    let birthday: String
    let weight: Double?
    let gender: String
    let sizeCategory: String
    let energyLevel: String
    let friendlinessDogs: Int
    let friendlinessPeople: Int
    let trainingLevel: String
    let favoriteActivities: [String]
    let isVaccinated: Bool
    let isSpayedNeutered: Bool
    let specialNeeds: String?
    let bio: String?
}

// MARK: - API Response Models
struct DogsResponse: Codable {
    let dogs: [Dog]
}

struct DogResponse: Codable {
    let message: String
    let dog: Dog
}

struct GalleryUploadResponse: Codable {
    let message: String
    let dog: Dog
    let uploadedImages: [String]
}

struct DogMembersResponse: Codable {
    let message: String
    let dog: Dog
    let members: [DogOwnerSummary]?
}

struct DogMembershipMutationResponse: Codable {
    let message: String
    let dog: Dog
}
