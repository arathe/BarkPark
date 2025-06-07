//
//  APIService.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation

// MARK: - API Configuration
struct APIConfiguration {
    static let baseURL = "http://localhost:3000/api"
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case noConnection
    case serverError(Int)
    case invalidData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No network connection"
        case .serverError(let code):
            return "Server error with code: \(code)"
        case .invalidData:
            return "Invalid data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = APIConfiguration.baseURL
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> RegisterResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(RegisterResponse.self, from: data)
    }
    
    func getCurrentUser() async throws -> User {
        let url = URL(string: "\(baseURL)/auth/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - Dog Profile Methods
    
    func getDogs() async throws -> [Dog] {
        let url = URL(string: "\(baseURL)/dogs")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode([Dog].self, from: data)
    }
    
    func createDog(_ dogRequest: CreateDogRequest) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(dogRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dogResponse = try decoder.decode(DogResponse.self, from: data)
        return dogResponse.dog
    }
    
    func getDog(id: Int) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Dog.self, from: data)
    }
    
    // MARK: - Photo Upload Methods
    
    func uploadProfileImage(dogId: Int, imageData: Data) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs/\(dogId)/profile-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (httpBody, contentType) = try createMultipartFormData(
            imageData: imageData,
            fieldName: "image",
            filename: "profile.jpg",
            mimeType: "image/jpeg"
        )
        
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        
        request.httpBody = httpBody
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dogResponse = try decoder.decode(DogResponse.self, from: data)
        return dogResponse.dog
    }
    
    func uploadGalleryImages(dogId: Int, imageDataArray: [Data]) async throws -> GalleryUploadResponse {
        let url = URL(string: "\(baseURL)/dogs/\(dogId)/gallery")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        
        for (index, imageData) in imageDataArray.enumerated() {
            let fieldName = "galleryImages"
            let filename = "gallery_\(index).jpg"
            let mimeType = "image/jpeg"
            
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            httpBody.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            httpBody.append(imageData)
            httpBody.append("\r\n".data(using: .utf8)!)
        }
        
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = httpBody
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try JSONDecoder().decode(GalleryUploadResponse.self, from: data)
    }
    
    // MARK: - Helper Methods
    
    func createMultipartFormData(
        imageData: Data,
        fieldName: String,
        filename: String,
        mimeType: String
    ) throws -> (Data, String) {
        let boundary = "Boundary-\(UUID().uuidString)"
        let contentType = "multipart/form-data; boundary=\(boundary)"
        
        let data = createMultipartBody(
            imageData: imageData,
            fieldName: fieldName,
            filename: filename,
            mimeType: mimeType,
            boundary: boundary
        )
        
        return (data, contentType)
    }
    
    private func createMultipartBody(
        imageData: Data,
        fieldName: String,
        filename: String,
        mimeType: String,
        boundary: String
    ) -> Data {
        var data = Data()
        
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return data
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        }
    }
}