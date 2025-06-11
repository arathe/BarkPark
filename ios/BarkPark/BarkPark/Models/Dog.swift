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
    let userId: Int
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
        userId = try container.decode(Int.self, forKey: .userId)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
    
    // CodingKeys for custom decoder
    private enum CodingKeys: String, CodingKey {
        case id, name, breed, birthday, age, weight, gender
        case sizeCategory, energyLevel, friendlinessDogs, friendlinessPeople
        case trainingLevel, favoriteActivities, isVaccinated, isSpayedNeutered
        case specialNeeds, bio, profileImageUrl, galleryImages, userId
        case createdAt, updatedAt
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