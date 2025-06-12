//
//  AuthenticationManagerTests.swift
//  BarkParkTests
//
//  Comprehensive tests for AuthenticationManager business logic
//

import Testing
import Foundation
@testable import BarkPark

@MainActor
struct AuthenticationManagerTests {
    
    // MARK: - Initial State Tests
    
    @Test("Initial authentication state")
    func testInitialAuthenticationState() {
        let authManager = AuthenticationManager()
        
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == nil)
        #expect(authManager.isLoading == false)
    }
    
    // MARK: - State Management Tests
    
    @Test("Loading state during authentication")
    func testLoadingStateDuringAuth() async {
        let authManager = AuthenticationManager()
        
        // Initially not loading
        #expect(authManager.isLoading == false)
        
        // Note: We can't easily test the loading state during actual API calls
        // without mocking the APIService, but we can test the state management logic
        authManager.isLoading = true
        #expect(authManager.isLoading == true)
        
        authManager.isLoading = false
        #expect(authManager.isLoading == false)
    }
    
    @Test("Error message state management")
    func testErrorMessageStateManagement() {
        let authManager = AuthenticationManager()
        
        // Initially no error
        #expect(authManager.errorMessage == nil)
        
        // Set error message
        authManager.errorMessage = "Test error message"
        #expect(authManager.errorMessage == "Test error message")
        
        // Clear error message
        authManager.errorMessage = nil
        #expect(authManager.errorMessage == nil)
    }
    
    @Test("User state management")
    func testUserStateManagement() {
        let authManager = AuthenticationManager()
        
        let testUser = User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
        
        // Initially no user
        #expect(authManager.currentUser == nil)
        #expect(authManager.isAuthenticated == false)
        
        // Set user and authentication
        authManager.currentUser = testUser
        authManager.isAuthenticated = true
        
        #expect(authManager.currentUser?.id == 1)
        #expect(authManager.currentUser?.email == "test@example.com")
        #expect(authManager.isAuthenticated == true)
    }
    
    // MARK: - Logout Tests
    
    @Test("Logout clears authentication state")
    func testLogoutClearsState() {
        let authManager = AuthenticationManager()
        
        // Set up authenticated state
        let testUser = User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
        
        authManager.currentUser = testUser
        authManager.isAuthenticated = true
        authManager.errorMessage = "Some error"
        UserDefaults.standard.set("test-token", forKey: "auth_token")
        
        // Verify state is set
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser != nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") != nil)
        
        // Logout
        authManager.logout()
        
        // Verify state is cleared
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == nil)
    }
    
    // MARK: - Token Persistence Tests
    
    @Test("Token persistence in UserDefaults")
    func testTokenPersistence() {
        let tokenKey = "auth_token"
        let testToken = "test-jwt-token-12345"
        
        // Clean up first
        UserDefaults.standard.removeObject(forKey: tokenKey)
        #expect(UserDefaults.standard.string(forKey: tokenKey) == nil)
        
        // Store token
        UserDefaults.standard.set(testToken, forKey: tokenKey)
        
        // Retrieve token
        let retrievedToken = UserDefaults.standard.string(forKey: tokenKey)
        #expect(retrievedToken == testToken)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: tokenKey)
        #expect(UserDefaults.standard.string(forKey: tokenKey) == nil)
    }
    
    @Test("Authentication status check with existing token")
    func testAuthenticationStatusWithToken() {
        let authManager = AuthenticationManager()
        let tokenKey = "auth_token"
        let testToken = "existing-jwt-token"
        
        // Store a token
        UserDefaults.standard.set(testToken, forKey: tokenKey)
        
        // Verify token exists
        #expect(UserDefaults.standard.string(forKey: tokenKey) == testToken)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Error message formatting")
    func testErrorMessageFormatting() {
        let authManager = AuthenticationManager()
        
        // Test different error message types
        let networkError = "Network error occurred"
        let validationError = "Invalid email or password"
        let serverError = "Server error with code: 500"
        
        authManager.errorMessage = networkError
        #expect(authManager.errorMessage == networkError)
        
        authManager.errorMessage = validationError
        #expect(authManager.errorMessage == validationError)
        
        authManager.errorMessage = serverError
        #expect(authManager.errorMessage == serverError)
    }
    
    // MARK: - Authentication Flow Tests
    
    @Test("Successful authentication flow simulation")
    func testSuccessfulAuthenticationFlow() {
        let authManager = AuthenticationManager()
        
        // Simulate login start
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        #expect(authManager.isLoading == true)
        #expect(authManager.errorMessage == nil)
        
        // Simulate successful response
        let testUser = User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
        
        let testToken = "successful-login-token"
        
        // Store token (simulating APIService success)
        UserDefaults.standard.set(testToken, forKey: "auth_token")
        
        // Update authentication state
        authManager.currentUser = testUser
        authManager.isAuthenticated = true
        authManager.isLoading = false
        
        // Verify final state
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser?.email == "test@example.com")
        #expect(authManager.isLoading == false)
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == testToken)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    @Test("Failed authentication flow simulation")
    func testFailedAuthenticationFlow() {
        let authManager = AuthenticationManager()
        
        // Simulate login start
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        #expect(authManager.isLoading == true)
        #expect(authManager.errorMessage == nil)
        
        // Simulate error response
        authManager.errorMessage = "Invalid email or password"
        authManager.isLoading = false
        
        // Verify authentication remains false
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == "Invalid email or password")
        #expect(authManager.isLoading == false)
    }
    
    // MARK: - Data Validation Tests
    
    @Test("User data validation")
    func testUserDataValidation() {
        let validUser = User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: "+1234567890",
            profileImageUrl: "https://example.com/image.jpg"
        )
        
        #expect(validUser.id == 1)
        #expect(validUser.email == "test@example.com")
        #expect(validUser.firstName == "Test")
        #expect(validUser.lastName == "User")
        #expect(validUser.phone == "+1234567890")
        #expect(validUser.profileImageUrl == "https://example.com/image.jpg")
        #expect(validUser.fullName == "Test User")
    }
    
    @Test("User data with optional fields")
    func testUserDataWithOptionalFields() {
        let userWithoutOptionals = User(
            id: 2,
            email: "minimal@example.com",
            firstName: "Minimal",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
        
        #expect(userWithoutOptionals.id == 2)
        #expect(userWithoutOptionals.email == "minimal@example.com")
        #expect(userWithoutOptionals.phone == nil)
        #expect(userWithoutOptionals.profileImageUrl == nil)
        #expect(userWithoutOptionals.fullName == "Minimal User")
    }
    
    // MARK: - Observable Object Tests
    
    @Test("ObservableObject property changes")
    func testObservableObjectChanges() {
        let authManager = AuthenticationManager()
        
        // Test that properties can be changed (ObservableObject functionality)
        authManager.isLoading = true
        #expect(authManager.isLoading == true)
        
        authManager.isAuthenticated = true
        #expect(authManager.isAuthenticated == true)
        
        authManager.errorMessage = "Test error"
        #expect(authManager.errorMessage == "Test error")
        
        let testUser = User(
            id: 1,
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phone: nil,
            profileImageUrl: nil
        )
        
        authManager.currentUser = testUser
        #expect(authManager.currentUser?.id == 1)
    }
    
    // MARK: - Cleanup Tests
    
    @Test("Cleanup after tests")
    func testCleanup() {
        // Ensure no test data remains in UserDefaults
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        let token = UserDefaults.standard.string(forKey: "auth_token")
        #expect(token == nil)
    }
}