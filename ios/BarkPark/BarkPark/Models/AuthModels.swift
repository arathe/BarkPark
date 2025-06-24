//
//  AuthModels.swift
//  BarkPark
//
//  Authentication request and response models
//

import Foundation

// MARK: - Request Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let firstName: String
    let lastName: String
}

struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let phone: String?
    let isSearchable: Bool
}

// MARK: - Response Models

struct ProfileImageUploadResponse: Codable {
    let message: String
    let profileImageUrl: String
}