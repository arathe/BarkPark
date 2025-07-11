//
//  APIService.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation

// MARK: - API Configuration
struct APIConfiguration {
    // Use your Mac's IP address for iOS Simulator
    // localhost doesn't work in the simulator
    static let baseURL = "http://192.168.86.67:3000/api"
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

@MainActor
class APIService {
    static let shared = APIService()
    
    private let baseURL = APIConfiguration.baseURL
    private let session = URLSession.shared
    private let networkManager: NetworkManager
    
    private init() {
        self.networkManager = NetworkManager(baseURL: baseURL, session: session)
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) async throws -> LoginResponse {
        print("🔐 APIService: Starting login for email: \(email)")
        
        let loginRequest = LoginRequest(email: email, password: password)
        let endpoint = try NetworkManager.Endpoint(
            path: "/auth/login",
            method: .POST,
            body: loginRequest,
            requiresAuth: false
        )
        
        print("🔐 APIService: Making login request")
        let response: LoginResponse = try await networkManager.request(endpoint, decoder: JSONDecoder())
        print("🔐 APIService: Login successful")
        return response
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws -> RegisterResponse {
        print("🔐 APIService: Starting registration for email: \(email)")
        
        let registerRequest = RegisterRequest(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        let endpoint = try NetworkManager.Endpoint(
            path: "/auth/register",
            method: .POST,
            body: registerRequest,
            requiresAuth: false
        )
        
        print("🔐 APIService: Making registration request")
        let response: RegisterResponse = try await networkManager.request(endpoint, decoder: JSONDecoder())
        print("🔐 APIService: Registration successful")
        return response
    }
    
    func getCurrentUser() async throws -> User {
        let endpoint = NetworkManager.Endpoint(
            path: "/auth/me",
            method: .GET
        )
        
        let response: CurrentUserResponse = try await networkManager.request(endpoint, decoder: JSONDecoder())
        return response.user
    }
    
    func updateUserProfile(firstName: String, lastName: String, phone: String?, isSearchable: Bool) async throws -> UserUpdateResponse {
        let updateRequest = UpdateProfileRequest(
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            isSearchable: isSearchable
        )
        
        let endpoint = try NetworkManager.Endpoint(
            path: "/auth/me",
            method: .PUT,
            body: updateRequest
        )
        
        return try await networkManager.request(endpoint, decoder: JSONDecoder())
    }
    
    func uploadProfileImage(imageData: Data) async throws -> ProfileImageUploadResponse {
        let url = URL(string: "\(baseURL)/auth/profile-image")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"profileImage\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(ProfileImageUploadResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid image data")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    // MARK: - Dog Profile Methods
    
    func getDogs() async throws -> [Dog] {
        print("🌐 APIService: Starting getDogs()")
        
        let endpoint = NetworkManager.Endpoint(
            path: "/dogs",
            method: .GET
        )
        
        print("🌐 APIService: Making request")
        let response: DogsResponse = try await networkManager.request(endpoint, decoder: JSONDecoder())
        print("🌐 APIService: Successfully decoded \(response.dogs.count) dogs")
        return response.dogs
    }
    
    func createDog(_ dogRequest: CreateDogRequest) async throws -> Dog {
        let endpoint = try NetworkManager.Endpoint(
            path: "/dogs",
            method: .POST,
            body: dogRequest
        )
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dogResponse: DogResponse = try await networkManager.request(endpoint, decoder: decoder)
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder.barkParkDecoder.decode(ParksSearchResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            print("🌐 APIService: Parks request failed with status \(httpResponse.statusCode)")
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("🌐 APIService: Response: \(responseString)")
            throw APIError.invalidResponse
        }
    }
    
    func getAllParks() async throws -> [DogPark] {
        let endpoint = NetworkManager.Endpoint(
            path: "/parks/all",
            method: .GET
        )
        
        let response: ParksResponse = try await networkManager.request(endpoint)
        return response.parks
    }
    
    func getParkDetails(parkId: Int) async throws -> ParkDetailResponse {
        let endpoint = NetworkManager.Endpoint(
            path: "/parks/\(parkId)",
            method: .GET
        )
        
        return try await networkManager.request(endpoint)
    }
    
    func getParkActivity(parkId: Int) async throws -> ParkActivityResponse {
        let endpoint = NetworkManager.Endpoint(
            path: "/parks/\(parkId)/activity",
            method: .GET
        )
        
        return try await networkManager.request(endpoint)
    }
    
    func getFriendsAtPark(parkId: Int) async throws -> FriendsAtParkResponse {
        let endpoint = NetworkManager.Endpoint(
            path: "/parks/\(parkId)/friends",
            method: .GET
        )
        
        return try await networkManager.request(endpoint)
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
            return try JSONDecoder.barkParkDecoder.decode(CheckInResponse.self, from: data)
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
            return try JSONDecoder.barkParkDecoder.decode(CheckOutResponse.self, from: data)
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
        
        return try JSONDecoder.barkParkDecoder.decode(CheckInHistoryResponse.self, from: data)
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
        
        return try JSONDecoder.barkParkDecoder.decode(ActiveCheckInsResponse.self, from: data)
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
        
        return try JSONDecoder.barkParkDecoder.decode(ParksSearchResponse.self, from: data)
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
    
    // MARK: - User Profile Methods
    
    func getUserProfile(userId: Int) async throws -> UserProfileResponse {
        let url = URL(string: "\(baseURL)/users/\(userId)/profile")!
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
            return try JSONDecoder().decode(UserProfileResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        case 403:
            throw APIError.validationFailed("You must be friends or have a pending friend request to view this profile")
        case 404:
            throw APIError.validationFailed("User not found")
        default:
            throw APIError.serverError
        }
    }
    
    // MARK: - Social Feed
    
    func getFeed(limit: Int = 20, offset: Int = 0) async throws -> FeedResponse {
        let url = URL(string: "\(baseURL)/posts/feed?limit=\(limit)&offset=\(offset)")!
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
            return try JSONDecoder.barkParkDecoder.decode(FeedResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func createPost(_ postRequest: CreatePostRequest) async throws -> Post {
        let url = URL(string: "\(baseURL)/posts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(postRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder.barkParkDecoder.decode(Post.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid post data")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func likePost(postId: Int) async throws -> Bool {
        let url = URL(string: "\(baseURL)/posts/\(postId)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            if let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let action = result["action"] as? String {
                return action == "liked"
            }
            return false
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func getNotifications(limit: Int = 50, offset: Int = 0) async throws -> NotificationsResponse {
        let url = URL(string: "\(baseURL)/notifications?limit=\(limit)&offset=\(offset)")!
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
            return try JSONDecoder.barkParkDecoder.decode(NotificationsResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func markNotificationAsRead(notificationId: Int) async throws {
        let url = URL(string: "\(baseURL)/notifications/\(notificationId)/read")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 404:
            throw APIError.validationFailed("Notification not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    // MARK: - Comments
    
    func getComments(postId: Int, limit: Int = 50, offset: Int = 0) async throws -> CommentsResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/comments?limit=\(limit)&offset=\(offset)")!
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
            return try JSONDecoder.barkParkDecoder.decode(CommentsResponse.self, from: data)
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
    
    func postComment(postId: Int, content: String, parentCommentId: Int? = nil) async throws -> CommentResponse {
        let url = URL(string: "\(baseURL)/posts/\(postId)/comment")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body: [String: Any] = ["content": content]
        if let parentId = parentCommentId {
            body["parentCommentId"] = parentId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 201:
            return try JSONDecoder.barkParkDecoder.decode(CommentResponse.self, from: data)
        case 404:
            throw APIError.validationFailed("Post not found")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        case 400:
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errors = errorData["errors"] as? [[String: Any]] {
                let messages = errors.compactMap { $0["msg"] as? String }.joined(separator: ", ")
                throw APIError.validationFailed(messages)
            }
            throw APIError.validationFailed("Invalid comment data")
        default:
            throw APIError.serverError
        }
    }
    
    func deleteComment(commentId: Int) async throws {
        let url = URL(string: "\(baseURL)/posts/comments/\(commentId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return
        case 404:
            throw APIError.validationFailed("Comment not found or you don't have permission to delete it")
        case 401:
            throw APIError.authenticationFailed("Authentication required")
        default:
            throw APIError.serverError
        }
    }
}

// MARK: - Password Reset
extension APIService {
    func requestPasswordReset(email: String) async throws -> PasswordResetResponse {
        let endpoint = "\(baseURL)/auth/forgot-password"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(PasswordResetResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONDecoder().decode(PasswordResetErrorResponse.self, from: data) {
                throw APIError.validationFailed(errorResponse.error)
            }
            throw APIError.validationFailed("Invalid request")
        case 429:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Too many requests")
        default:
            throw APIError.serverError
        }
    }
    
    func resetPassword(token: String, newPassword: String) async throws -> ResetPasswordResponse {
        let endpoint = "\(baseURL)/auth/reset-password"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "token": token,
            "password": newPassword
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(ResetPasswordResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid or expired reset token")
        default:
            throw APIError.serverError
        }
    }
    
    func verifyResetToken(token: String) async throws -> VerifyTokenResponse {
        let endpoint = "\(baseURL)/auth/verify-reset-token?token=\(token)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(VerifyTokenResponse.self, from: data)
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Invalid token")
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