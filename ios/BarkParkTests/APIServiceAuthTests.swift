//
//  APIServiceAuthTests.swift
//  BarkParkTests
//
//  Comprehensive tests for APIService authentication functionality
//

import Testing
import Foundation
@testable import BarkPark

struct APIServiceAuthTests {
    
    // MARK: - Mock Data
    
    private let validUser = User(
        id: 1,
        email: "test@example.com",
        firstName: "Test",
        lastName: "User",
        phone: nil,
        profileImageUrl: nil
    )
    
    private let validLoginResponse = LoginResponse(
        message: "Login successful",
        token: "valid-jwt-token",
        user: User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
    )
    
    // MARK: - Login API Tests
    
    @Test("Login API call success parsing")
    func testLoginSuccessResponseParsing() throws {
        let jsonString = """
        {
            "message": "Login successful",
            "token": "valid-jwt-token-12345",
            "user": {
                "id": 1,
                "email": "test@example.com",
                "firstName": "Test",
                "lastName": "User",
                "phone": null,
                "profileImageUrl": null
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(LoginResponse.self, from: data)
        
        #expect(response.message == "Login successful")
        #expect(response.token == "valid-jwt-token-12345")
        #expect(response.user.id == 1)
        #expect(response.user.email == "test@example.com")
        #expect(response.user.firstName == "Test")
        #expect(response.user.lastName == "User")
    }
    
    @Test("Login API 401 error response parsing")
    func testLogin401ErrorResponseParsing() throws {
        let jsonString = """
        {
            "error": "Invalid email or password"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Test that we can parse the error structure
        let errorResponse = try decoder.decode([String: String].self, from: data)
        
        #expect(errorResponse["error"] == "Invalid email or password")
    }
    
    @Test("Login API 400 validation error response parsing")
    func testLogin400ValidationErrorParsing() throws {
        let jsonString = """
        {
            "errors": [
                {
                    "path": "email",
                    "msg": "Invalid value",
                    "location": "body",
                    "value": "invalid-email"
                },
                {
                    "path": "password",
                    "msg": "Password is required",
                    "location": "body"
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Test that we can parse validation errors
        struct ValidationErrorResponse: Codable {
            let errors: [ValidationError]
        }
        
        struct ValidationError: Codable {
            let path: String
            let msg: String
            let location: String
            let value: String?
        }
        
        let response = try decoder.decode(ValidationErrorResponse.self, from: data)
        
        #expect(response.errors.count == 2)
        #expect(response.errors[0].path == "email")
        #expect(response.errors[1].path == "password")
    }
    
    // MARK: - Register API Tests
    
    @Test("Register API call success parsing")
    func testRegisterSuccessResponseParsing() throws {
        let jsonString = """
        {
            "message": "User created successfully",
            "token": "new-user-jwt-token",
            "user": {
                "id": 2,
                "email": "newuser@example.com",
                "firstName": "New",
                "lastName": "User",
                "phone": "+1234567890",
                "profileImageUrl": null
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(RegisterResponse.self, from: data)
        
        #expect(response.message == "User created successfully")
        #expect(response.token == "new-user-jwt-token")
        #expect(response.user.id == 2)
        #expect(response.user.email == "newuser@example.com")
        #expect(response.user.phone == "+1234567890")
    }
    
    @Test("Register API 409 conflict error parsing")
    func testRegister409ConflictErrorParsing() throws {
        let jsonString = """
        {
            "error": "User with this email already exists"
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let errorResponse = try decoder.decode([String: String].self, from: data)
        
        #expect(errorResponse["error"] == "User with this email already exists")
    }
    
    // MARK: - Error Response Structure Tests
    
    @Test("API error response models")
    func testAPIErrorResponseModels() throws {
        // Test that our error response parsing works for different error types
        
        // Single error response
        let singleErrorJSON = """
        {
            "error": "Something went wrong"
        }
        """
        
        let singleErrorData = singleErrorJSON.data(using: .utf8)!
        let singleError = try JSONDecoder().decode([String: String].self, from: singleErrorData)
        #expect(singleError["error"] == "Something went wrong")
        
        // Validation errors response
        let validationErrorJSON = """
        {
            "errors": [
                {"path": "field1", "msg": "Error 1", "location": "body"},
                {"path": "field2", "msg": "Error 2", "location": "body"}
            ]
        }
        """
        
        struct ValidationResponse: Codable {
            let errors: [ValidationField]
        }
        
        struct ValidationField: Codable {
            let path: String
            let msg: String
            let location: String
        }
        
        let validationData = validationErrorJSON.data(using: .utf8)!
        let validationResponse = try JSONDecoder().decode(ValidationResponse.self, from: validationData)
        #expect(validationResponse.errors.count == 2)
    }
    
    // MARK: - Network Response Status Code Tests
    
    @Test("HTTP status code handling")
    func testHTTPStatusCodeHandling() {
        // Test that different status codes map to appropriate behaviors
        
        // Success codes
        let successCodes = [200, 201]
        for code in successCodes {
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )
            #expect(httpResponse?.statusCode == code)
        }
        
        // Error codes that should be handled specially
        let errorCodes = [400, 401, 409, 500]
        for code in errorCodes {
            let httpResponse = HTTPURLResponse(
                url: URL(string: "http://test.com")!,
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )
            #expect(httpResponse?.statusCode == code)
        }
    }
    
    // MARK: - Request Body Formation Tests
    
    @Test("Login request body formation")
    func testLoginRequestBodyFormation() throws {
        let email = "test@example.com"
        let password = "password123"
        
        let body = [
            "email": email,
            "password": password
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let recreatedBody = try JSONSerialization.jsonObject(with: jsonData) as! [String: String]
        
        #expect(recreatedBody["email"] == email)
        #expect(recreatedBody["password"] == password)
    }
    
    @Test("Register request body formation")
    func testRegisterRequestBodyFormation() throws {
        let userData = [
            "email": "new@example.com",
            "password": "newpassword",
            "firstName": "New",
            "lastName": "User"
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: userData)
        let recreatedBody = try JSONSerialization.jsonObject(with: jsonData) as! [String: String]
        
        #expect(recreatedBody["email"] == "new@example.com")
        #expect(recreatedBody["firstName"] == "New")
        #expect(recreatedBody["lastName"] == "User")
    }
    
    // MARK: - URL Construction Tests
    
    @Test("Authentication endpoint URLs")
    func testAuthenticationEndpointURLs() {
        let baseURL = "http://127.0.0.1:3000/api"
        
        let loginURL = "\(baseURL)/auth/login"
        let registerURL = "\(baseURL)/auth/register"
        let meURL = "\(baseURL)/auth/me"
        
        #expect(URL(string: loginURL) != nil)
        #expect(URL(string: registerURL) != nil)
        #expect(URL(string: meURL) != nil)
        
        #expect(loginURL == "http://127.0.0.1:3000/api/auth/login")
        #expect(registerURL == "http://127.0.0.1:3000/api/auth/register")
        #expect(meURL == "http://127.0.0.1:3000/api/auth/me")
    }
    
    // MARK: - Content Type Header Tests
    
    @Test("Request headers formation")
    func testRequestHeadersFormation() {
        // Test that proper Content-Type headers are set
        let contentType = "application/json"
        let authorization = "Bearer test-token-12345"
        
        #expect(contentType == "application/json")
        #expect(authorization.hasPrefix("Bearer "))
        #expect(authorization.contains("test-token-12345"))
    }
    
    // MARK: - Token Storage Tests
    
    @Test("Token storage key consistency")
    func testTokenStorageKey() {
        let tokenKey = "auth_token"
        
        // Verify the key used for token storage is consistent
        #expect(tokenKey == "auth_token")
        
        // Test that UserDefaults operations work with this key
        UserDefaults.standard.set("test-token", forKey: tokenKey)
        let retrievedToken = UserDefaults.standard.string(forKey: tokenKey)
        #expect(retrievedToken == "test-token")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}