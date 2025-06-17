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

// MARK: - View Model
@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfileResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func fetchUserProfile(userId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: UserProfileResponse = try await networkManager.request(
                endpoint: "/users/\(userId)/profile",
                method: .get
            )
            
            self.userProfile = response
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .forbidden:
                    errorMessage = "You must be friends or have a pending friend request to view this profile"
                case .notFound:
                    errorMessage = "User not found"
                default:
                    errorMessage = "Failed to load profile"
                }
            } else {
                errorMessage = "An unexpected error occurred"
            }
            print("UserProfileViewModel: Failed to fetch profile - \(error)")
        }
        
        isLoading = false
    }
}