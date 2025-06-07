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
    let breed: String
    let birthday: String
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
    
    // Computed properties
    var computedAge: Int {
        // Use backend-provided age if available, otherwise compute it
        if let age = age { return age }
        
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

// MARK: - Photo Upload Response Models
struct DogResponse: Codable {
    let message: String
    let dog: Dog
}

struct GalleryUploadResponse: Codable {
    let message: String
    let imageUrls: [String]
    let dog: Dog
    let uploadedImages: [String]
}