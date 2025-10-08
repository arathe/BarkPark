//
//  User.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let profileImageUrl: String?
    let isSearchable: Bool? = nil
    let dogs: [UserDogSummary]? = nil

    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct UserDogSummary: Codable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - Authentication Response Models
struct LoginResponse: Codable {
    let message: String
    let token: String
    let user: User
}

struct RegisterResponse: Codable {
    let message: String
    let token: String
    let user: User
}

struct UserUpdateResponse: Codable {
    let message: String
    let user: User
}

struct CurrentUserResponse: Codable {
    let user: User
}