//
//  UserProfileViewModel.swift
//  BarkPark
//
//  Created by Assistant on 6/17/25.
//

import Foundation
import SwiftUI

// MARK: - User Profile Response Models
struct UserProfileResponse: Codable {
    let user: UserProfileUser
    let dogs: [UserProfileDog]
    let recentCheckIns: [UserProfileCheckIn]
}

struct UserProfileUser: Codable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let fullName: String
    let profileImageUrl: String?
    let createdAt: String?
}

struct UserProfileDog: Codable, Identifiable {
    let id: Int
    let name: String
    let breed: String?
    let age: Int?
    let gender: String?
    let weight: Double?
    let description: String?
    let profileImageUrl: String?
    let createdAt: String?
}

struct UserProfileCheckIn: Codable, Identifiable {
    let id: Int
    let parkName: String
    let parkAddress: String
    let checkedInAt: String
    let checkedOutAt: String?
    let dogsPresent: [Int]
}

// MARK: - View Model
@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfileResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func fetchUserProfile(userId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getUserProfile(userId: userId)
            self.userProfile = response
            print("✅ UserProfileViewModel: Loaded profile for user \(userId)")
        } catch {
            print("❌ UserProfileViewModel: Failed to fetch profile - \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}