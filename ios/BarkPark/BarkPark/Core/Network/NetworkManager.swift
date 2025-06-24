import Foundation

/// Centralized network manager to reduce code duplication in APIService
@MainActor
class NetworkManager {
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// HTTP methods supported by the API
    enum HTTPMethod: String {
        case GET, POST, PUT, DELETE, PATCH
    }
    
    /// Configuration for an API endpoint
    struct Endpoint {
        let path: String
        let method: HTTPMethod
        let body: Data?
        let queryItems: [URLQueryItem]?
        let requiresAuth: Bool
        let contentType: String?
        
        init(
            path: String,
            method: HTTPMethod,
            body: Data? = nil,
            queryItems: [URLQueryItem]? = nil,
            requiresAuth: Bool = true,
            contentType: String? = "application/json"
        ) {
            self.path = path
            self.method = method
            self.body = body
            self.queryItems = queryItems
            self.requiresAuth = requiresAuth
            self.contentType = contentType
        }
        
        /// Convenience initializer for JSON body
        init<T: Encodable>(
            path: String,
            method: HTTPMethod,
            body: T,
            queryItems: [URLQueryItem]? = nil,
            requiresAuth: Bool = true
        ) throws {
            self.path = path
            self.method = method
            self.body = try JSONEncoder().encode(body)
            self.queryItems = queryItems
            self.requiresAuth = requiresAuth
            self.contentType = "application/json"
        }
    }
    
    /// Perform a network request and decode the response
    func request<T: Decodable>(_ endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder.barkParkDecoder) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try handleResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }
    
    /// Perform a network request without expecting a response body
    func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try handleResponse(response, data: data)
    }
    
    /// Perform a network request and return raw data
    func requestData(_ endpoint: Endpoint) async throws -> Data {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try handleResponse(response, data: data)
        return data
    }
    
    /// Build URLRequest from endpoint configuration
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: "\(baseURL)\(endpoint.path)") else {
            throw APIError.invalidResponse
        }
        
        if let queryItems = endpoint.queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add auth header if required
        if endpoint.requiresAuth {
            guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
                throw APIError.authenticationFailed("No auth token available")
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add content type if provided
        if let contentType = endpoint.contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        // Add body if provided
        request.httpBody = endpoint.body
        
        return request
    }
    
    /// Handle HTTP response and throw appropriate errors
    private func handleResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 400:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            if let errors = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorArray = errors["errors"] as? [[String: Any]],
               let firstError = errorArray.first,
               let msg = firstError["msg"] as? String {
                throw APIError.validationFailed(msg)
            }
            throw APIError.validationFailed("Invalid request")
        case 401:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.authenticationFailed(errorMessage)
            }
            throw APIError.authenticationFailed("Authentication required")
        case 403:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Access denied")
        case 404:
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw APIError.validationFailed(errorMessage)
            }
            throw APIError.validationFailed("Resource not found")
        case 500...599:
            throw APIError.serverError
        default:
            throw APIError.invalidResponse
        }
    }
}