//
//  APIService.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation

// MARK: - API Configuration
struct APIConfiguration {
    static let baseURL = "http://127.0.0.1:3000/api"
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
        print("🔐 APIService: Starting login for email: \(email)")
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("🔐 APIService: Making login request to \(url)")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔐 APIService: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔐 APIService: Login response status: \(httpResponse.statusCode)")
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 200:
            print("🔐 APIService: Login successful, decoding response")
            return try JSONDecoder().decode(LoginResponse.self, from: data)
            
        case 400, 401:
            // Try to decode error message from backend
            print("🔐 APIService: Login failed with status \(httpResponse.statusCode)")
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                print("🔐 APIService: Backend error message: \(errorMessage)")
                throw APIError.authenticationFailed(errorMessage)
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("🔐 APIService: Raw error response: \(responseString)")
                throw APIError.authenticationFailed("Invalid email or password")
            }
            
        case 500...599:
            print("🔐 APIService: Server error: \(httpResponse.statusCode)")
            throw APIError.serverError
            
        default:
            print("🔐 APIService: Unexpected status code: \(httpResponse.statusCode)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🔐 APIService: Raw response: \(responseString)")
            throw APIError.invalidResponse
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> RegisterResponse {
        print("🔐 APIService: Starting registration for email: \(email)")
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
        
        print("🔐 APIService: Making register request to \(url)")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔐 APIService: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🔐 APIService: Register response status: \(httpResponse.statusCode)")
        
        // Handle different status codes
        switch httpResponse.statusCode {
        case 201:
            print("🔐 APIService: Registration successful, decoding response")
            return try JSONDecoder().decode(RegisterResponse.self, from: data)
            
        case 400:
            // Validation errors
            print("🔐 APIService: Registration validation failed")
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errors = errorResponse["errors"] as? [[String: Any]], !errors.isEmpty {
                    let errorMessages = errors.compactMap { $0["msg"] as? String }
                    let message = errorMessages.joined(separator: ", ")
                    print("🔐 APIService: Validation errors: \(message)")
                    throw APIError.validationFailed(message)
                } else if let errorMessage = errorResponse["error"] as? String {
                    print("🔐 APIService: Backend error: \(errorMessage)")
                    throw APIError.authenticationFailed(errorMessage)
                }
            }
            throw APIError.validationFailed("Invalid registration data")
            
        case 409:
            // User already exists
            print("🔐 APIService: User already exists")
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.authenticationFailed(errorMessage)
            }
            throw APIError.authenticationFailed("User with this email already exists")
            
        case 500...599:
            print("🔐 APIService: Server error: \(httpResponse.statusCode)")
            throw APIError.serverError
            
        default:
            print("🔐 APIService: Unexpected status code: \(httpResponse.statusCode)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🔐 APIService: Raw response: \(responseString)")
            throw APIError.invalidResponse
        }
    }
    
    func getCurrentUser() async throws -> User {
        let url = URL(string: "\(baseURL)/auth/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let response = try JSONDecoder().decode(CurrentUserResponse.self, from: data)
            return response.user
        case 401:
            throw APIError.authenticationFailed("Unauthorized")
        default:
            throw APIError.invalidResponse
        }
    }
    
    func updateUserProfile(firstName: String, lastName: String, phone: String?, isSearchable: Bool) async throws -> UserUpdateResponse {
        let url = URL(string: "\(baseURL)/auth/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "isSearchable": isSearchable
        ]
        
        if let phone = phone {
            body["phone"] = phone
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(UserUpdateResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid profile data")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    // MARK: - Dog Profile Methods
    
    func getDogs() async throws -> [Dog] {
        print("🌐 APIService: Starting getDogs()")
        let url = URL(string: "\(baseURL)/dogs")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let token = UserDefaults.standard.string(forKey: "auth_token")
        print("🌐 APIService: Token exists: \(token != nil)")
        if let token = token {
            print("🌐 APIService: Using token: \(String(token.prefix(20)))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("🌐 APIService: No auth token found!")
        }
        
        print("🌐 APIService: Making request to \(url)")
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("🌐 APIService: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🌐 APIService: HTTP Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🌐 APIService: Error response: \(responseString)")
            throw APIError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("🌐 APIService: Raw response (\(data.count) bytes): \(String(responseString.prefix(200)))...")
        
        do {
            let decodedResponse = try JSONDecoder().decode(DogsResponse.self, from: data)
            print("🌐 APIService: Successfully decoded \(decodedResponse.dogs.count) dogs")
            return decodedResponse.dogs
        } catch {
            print("🌐 APIService: JSON decoding error: \(error)")
            throw APIError.decodingError
        }
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
    
    func updateDog(dogId: Int, updateRequest: UpdateDogRequest) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs/\(dogId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
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
            let fieldName = "images"
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
    
    func setProfileImageFromGallery(dogId: Int, imageUrl: String) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs/\(dogId)/profile-image-from-gallery")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["imageUrl": imageUrl]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
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
    
    func removeGalleryImage(dogId: Int, imageUrl: String) async throws -> Dog {
        let url = URL(string: "\(baseURL)/dogs/\(dogId)/gallery")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["imageUrl": imageUrl]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
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
    
    func deleteDog(id: Int) async throws {
        let url = URL(string: "\(baseURL)/dogs/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
    
    // MARK: - Dog Park Methods
    
    func getNearbyParks(latitude: Double, longitude: Double, radius: Double = 10.0) async throws -> ParksSearchResponse {
        let url = URL(string: "\(baseURL)/parks?latitude=\(latitude)&longitude=\(longitude)&radius=\(radius)")!
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
        
        return try JSONDecoder().decode(ParksSearchResponse.self, from: data)
    }
    
    func getAllParks() async throws -> [DogPark] {
        let url = URL(string: "\(baseURL)/parks/all")!
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
        
        let parkResponse = try JSONDecoder().decode(ParksResponse.self, from: data)
        return parkResponse.parks
    }
    
    func getParkDetails(parkId: Int) async throws -> ParkDetailResponse {
        let url = URL(string: "\(baseURL)/parks/\(parkId)")!
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
        
        return try JSONDecoder().decode(ParkDetailResponse.self, from: data)
    }
    
    func getParkActivity(parkId: Int) async throws -> ParkActivityResponse {
        let url = URL(string: "\(baseURL)/parks/\(parkId)/activity")!
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
        
        return try JSONDecoder().decode(ParkActivityResponse.self, from: data)
    }
    
    func getFriendsAtPark(parkId: Int) async throws -> FriendsAtParkResponse {
        let url = URL(string: "\(baseURL)/parks/\(parkId)/friends")!
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
        
        return try JSONDecoder().decode(FriendsAtParkResponse.self, from: data)
    }
    
    func checkInToPark(parkId: Int, dogsPresent: [Int] = []) async throws -> CheckInResponse {
        let url = URL(string: "\(baseURL)/parks/\(parkId)/checkin")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let checkInRequest = CheckInRequest(dogsPresent: dogsPresent)
        request.httpBody = try JSONEncoder().encode(checkInRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🌐 APIService: Check-in failed with status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("🌐 APIService: Response: \(responseString)")
            throw APIError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("🌐 APIService: Check-in response: \(responseString)")
        
        do {
            return try JSONDecoder().decode(CheckInResponse.self, from: data)
        } catch {
            print("🌐 APIService: Failed to decode CheckInResponse: \(error)")
            print("🌐 APIService: Response was: \(responseString)")
            throw APIError.decodingError
        }
    }
    
    func checkOutOfPark(parkId: Int) async throws -> CheckOutResponse {
        let url = URL(string: "\(baseURL)/parks/\(parkId)/checkout")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🌐 APIService: Check-out failed with status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("🌐 APIService: Response: \(responseString)")
            throw APIError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("🌐 APIService: Check-out response: \(responseString)")
        
        do {
            return try JSONDecoder().decode(CheckOutResponse.self, from: data)
        } catch {
            print("🌐 APIService: Failed to decode CheckOutResponse: \(error)")
            print("🌐 APIService: Response was: \(responseString)")
            throw APIError.decodingError
        }
    }
    
    func getCheckInHistory(limit: Int = 10) async throws -> CheckInHistoryResponse {
        let url = URL(string: "\(baseURL)/parks/user/history?limit=\(limit)")!
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
        
        return try JSONDecoder().decode(CheckInHistoryResponse.self, from: data)
    }
    
    func getActiveCheckIns() async throws -> ActiveCheckInsResponse {
        let url = URL(string: "\(baseURL)/parks/user/active")!
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
        
        return try JSONDecoder().decode(ActiveCheckInsResponse.self, from: data)
    }
    
    func searchParks(query: String, latitude: Double? = nil, longitude: Double? = nil) async throws -> ParksSearchResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/parks/search")!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "q", value: query)]
        
        if let latitude = latitude, let longitude = longitude {
            queryItems.append(URLQueryItem(name: "latitude", value: String(latitude)))
            queryItems.append(URLQueryItem(name: "longitude", value: String(longitude)))
        }
        
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidResponse
        }
        
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
        
        // Debug logging
        let responseString = String(data: data, encoding: .utf8) ?? "No response"
        print("🔍 APIService: Search response: \(responseString)")
        
        return try JSONDecoder().decode(ParksSearchResponse.self, from: data)
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
    
    // MARK: - Friendship Methods
    
    func searchUsers(query: String) async throws -> UserSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/auth/search?q=\(encodedQuery)")!
        var request = URLRequest(url: url)
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(UserSearchResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid search query")
        default:
            throw APIError.serverError
        }
    }
    
    func sendFriendRequest(to userId: Int) async throws -> SendFriendRequestResponse {
        let url = URL(string: "\(baseURL)/friends/request")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["userId": userId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder().decode(SendFriendRequestResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Unable to send friend request")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func acceptFriendRequest(friendshipId: Int) async throws -> FriendRequestActionResponse {
        let url = URL(string: "\(baseURL)/friends/\(friendshipId)/accept")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(FriendRequestActionResponse.self, from: data)
        case 404:
            throw APIError.validationFailed("Friend request not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func declineFriendRequest(friendshipId: Int) async throws -> FriendRequestActionResponse {
        let url = URL(string: "\(baseURL)/friends/\(friendshipId)/decline")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(FriendRequestActionResponse.self, from: data)
        case 404:
            throw APIError.validationFailed("Friend request not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func cancelFriendRequest(friendshipId: Int) async throws -> RemoveFriendResponse {
        let url = URL(string: "\(baseURL)/friends/\(friendshipId)/cancel")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(RemoveFriendResponse.self, from: data)
        case 404:
            throw APIError.validationFailed("Friend request not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func getFriends() async throws -> FriendsListResponse {
        let url = URL(string: "\(baseURL)/friends")!
        var request = URLRequest(url: url)
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(FriendsListResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func getFriendRequests() async throws -> FriendRequestsResponse {
        let url = URL(string: "\(baseURL)/friends/requests")!
        var request = URLRequest(url: url)
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(FriendRequestsResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func removeFriend(friendId: Int) async throws -> RemoveFriendResponse {
        let url = URL(string: "\(baseURL)/friends/\(friendId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(RemoveFriendResponse.self, from: data)
        case 404:
            throw APIError.validationFailed("Friendship not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func getFriendshipStatus(with userId: Int) async throws -> FriendshipStatusResponse {
        let url = URL(string: "\(baseURL)/friends/status/\(userId)")!
        var request = URLRequest(url: url)
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(FriendshipStatusResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func connectViaQRCode(qrData: String) async throws -> QRConnectResponse {
        let url = URL(string: "\(baseURL)/friends/qr-connect")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["qrData": qrData]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder().decode(QRConnectResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid QR code")
        case 404:
            throw APIError.validationFailed("User not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidResponse
    case decodingError
    case networkError
    case authenticationFailed(String)
    case validationFailed(String)
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network error occurred"
        case .authenticationFailed(let message):
            return message
        case .validationFailed(let message):
            return message
        case .serverError:
            return "Server error occurred. Please try again later."
        }
    }
}