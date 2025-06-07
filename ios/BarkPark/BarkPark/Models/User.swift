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
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
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