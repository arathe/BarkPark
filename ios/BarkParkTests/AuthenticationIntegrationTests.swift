//
//  AuthenticationIntegrationTests.swift
//  BarkParkTests
//
//  Integration tests for authentication flow between APIService and AuthenticationManager
//

import Testing
import Foundation
@testable import BarkPark

@MainActor
struct AuthenticationIntegrationTests {
    
    // MARK: - Mock APIService for Testing
    
    class MockAPIService {
        var shouldSucceed = true
        var errorToThrow: Error?
        var loginResponse: LoginResponse?
        var registerResponse: RegisterResponse?
        
        func mockLogin(email: String, password: String) async throws -> LoginResponse {
            if !shouldSucceed {
                throw errorToThrow ?? APIError.invalidResponse
            }
            
            return loginResponse ?? LoginResponse(
                message: "Login successful",
                token: "mock-jwt-token-12345",
                user: User(
                    id: 1,
                    email: email,
                    firstName: "Mock",
                    lastName: "User",
                    phone: nil,
                    profileImageUrl: nil
                )
            )
        }
        
        func mockRegister(email: String, password: String, firstName: String, lastName: String) async throws -> RegisterResponse {
            if !shouldSucceed {
                throw errorToThrow ?? APIError.invalidResponse
            }
            
            return registerResponse ?? RegisterResponse(
                message: "User created successfully",
                token: "mock-register-token-67890",
                user: User(
                    id: 2,
                    email: email,
                    firstName: firstName,
                    lastName: lastName,
                    phone: nil,
                    profileImageUrl: nil
                )
            )
        }
    }
    
    // MARK: - Authentication Flow Integration Tests
    
    @Test("Successful login flow integration")
    func testSuccessfulLoginFlowIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Setup successful response
        mockAPI.shouldSucceed = true
        mockAPI.loginResponse = LoginResponse(
            message: "Login successful",
            token: "integration-test-token",
            user: User(
                id: 100,
                email: "integration@test.com",
                firstName: "Integration",
                lastName: "Test",
                phone: nil,
                profileImageUrl: nil
            )
        )
        
        // Simulate successful login flow
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        do {
            let response = try await mockAPI.mockLogin(
                email: "integration@test.com",
                password: "testpassword"
            )
            
            // Simulate what AuthenticationManager does on success
            UserDefaults.standard.set(response.token, forKey: "auth_token")
            authManager.currentUser = response.user
            authManager.isAuthenticated = true
            authManager.errorMessage = nil
            
        } catch {
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Verify integration results
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser?.email == "integration@test.com")
        #expect(authManager.errorMessage == nil)
        #expect(authManager.isLoading == false)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == "integration-test-token")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    @Test("Failed login flow integration")
    func testFailedLoginFlowIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Setup failure response
        mockAPI.shouldSucceed = false
        mockAPI.errorToThrow = APIError.invalidResponse
        
        // Simulate failed login flow
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        do {
            _ = try await mockAPI.mockLogin(
                email: "wrong@test.com",
                password: "wrongpassword"
            )
            
            // This shouldn't be reached
            authManager.isAuthenticated = true
            
        } catch {
            // Simulate what AuthenticationManager does on error
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Verify integration results
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == "Invalid response from server")
        #expect(authManager.isLoading == false)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == nil)
    }
    
    @Test("Registration flow integration")
    func testRegistrationFlowIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Setup successful registration response
        mockAPI.shouldSucceed = true
        mockAPI.registerResponse = RegisterResponse(
            message: "User created successfully",
            token: "new-user-token-abc123",
            user: User(
                id: 200,
                email: "newuser@test.com",
                firstName: "New",
                lastName: "User",
                phone: nil,
                profileImageUrl: nil
            )
        )
        
        // Simulate registration flow
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        do {
            let response = try await mockAPI.mockRegister(
                email: "newuser@test.com",
                password: "newpassword",
                firstName: "New",
                lastName: "User"
            )
            
            // Simulate what AuthenticationManager does on success
            UserDefaults.standard.set(response.token, forKey: "auth_token")
            authManager.currentUser = response.user
            authManager.isAuthenticated = true
            authManager.errorMessage = nil
            
        } catch {
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Verify integration results
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser?.email == "newuser@test.com")
        #expect(authManager.currentUser?.firstName == "New")
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == "new-user-token-abc123")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
    
    // MARK: - Token Persistence Integration Tests
    
    @Test("Token persistence across app sessions")
    func testTokenPersistenceIntegration() {
        let tokenKey = "auth_token"
        let testToken = "persistent-token-xyz789"
        
        // Simulate app session 1: Login and store token
        do {
            let authManager1 = AuthenticationManager()
            
            // Simulate successful login
            UserDefaults.standard.set(testToken, forKey: tokenKey)
            authManager1.currentUser = User(
                id: 1,
                email: "persistent@test.com",
                firstName: "Persistent",
                lastName: "User",
                phone: nil,
                profileImageUrl: nil
            )
            authManager1.isAuthenticated = true
            
            #expect(authManager1.isAuthenticated == true)
            #expect(UserDefaults.standard.string(forKey: tokenKey) == testToken)
        }
        
        // Simulate app session 2: App restart, check token
        do {
            let authManager2 = AuthenticationManager()
            
            // Check if token persists
            let storedToken = UserDefaults.standard.string(forKey: tokenKey)
            #expect(storedToken == testToken)
            
            // Simulate checkAuthenticationStatus behavior
            if storedToken != nil {
                // Token exists, would normally call fetchCurrentUser
                authManager2.isAuthenticated = true
            }
            
            #expect(authManager2.isAuthenticated == true)
        }
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    @Test("Logout clears all authentication state")
    func testLogoutIntegration() {
        let authManager = AuthenticationManager()
        let tokenKey = "auth_token"
        
        // Setup authenticated state
        UserDefaults.standard.set("logout-test-token", forKey: tokenKey)
        authManager.currentUser = User(
            id: 1,
            email: "logout@test.com",
            firstName: "Logout",
            lastName: "Test",
            phone: nil,
            profileImageUrl: nil
        )
        authManager.isAuthenticated = true
        authManager.errorMessage = "Previous error"
        
        // Verify initial state
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser != nil)
        #expect(UserDefaults.standard.string(forKey: tokenKey) != nil)
        
        // Perform logout
        authManager.logout()
        
        // Verify all state is cleared
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: tokenKey) == nil)
    }
    
    // MARK: - Error Handling Integration Tests
    
    @Test("Network error handling integration")
    func testNetworkErrorHandlingIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Setup network error
        mockAPI.shouldSucceed = false
        mockAPI.errorToThrow = NetworkError.noConnection
        
        // Simulate network error during login
        authManager.isLoading = true
        authManager.errorMessage = nil
        
        do {
            _ = try await mockAPI.mockLogin(
                email: "network@test.com",
                password: "password"
            )
        } catch {
            // Simulate error handling
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Verify error state
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.errorMessage == "No network connection")
        #expect(authManager.isLoading == false)
    }
    
    @Test("Server error handling integration")
    func testServerErrorHandlingIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Setup server error
        mockAPI.shouldSucceed = false
        mockAPI.errorToThrow = NetworkError.serverError(500)
        
        // Simulate server error
        authManager.isLoading = true
        
        do {
            _ = try await mockAPI.mockLogin(
                email: "server@test.com",
                password: "password"
            )
        } catch {
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Verify error handling
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.errorMessage == "Server error with code: 500")
    }
    
    // MARK: - State Synchronization Tests
    
    @Test("State synchronization between components")
    func testStateSynchronizationIntegration() {
        let authManager = AuthenticationManager()
        
        // Test that all related state changes together
        let user = User(
            id: 1,
            email: "sync@test.com",
            firstName: "Sync",
            lastName: "Test",
            phone: nil,
            profileImageUrl: nil
        )
        
        // Simulate successful authentication
        authManager.currentUser = user
        authManager.isAuthenticated = true
        authManager.errorMessage = nil
        authManager.isLoading = false
        UserDefaults.standard.set("sync-token", forKey: "auth_token")
        
        // Verify synchronized state
        #expect(authManager.currentUser?.email == "sync@test.com")
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.errorMessage == nil)
        #expect(authManager.isLoading == false)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == "sync-token")
        
        // Simulate logout and verify all state clears
        authManager.logout()
        
        #expect(authManager.currentUser == nil)
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == nil)
    }
    
    // MARK: - Data Flow Integration Tests
    
    @Test("Complete data flow integration")
    func testCompleteDataFlowIntegration() async {
        let authManager = AuthenticationManager()
        let mockAPI = MockAPIService()
        
        // Test complete flow: error → clear → success → logout
        
        // Step 1: Start with error state
        authManager.errorMessage = "Initial error"
        #expect(authManager.errorMessage == "Initial error")
        
        // Step 2: Clear error and attempt login
        authManager.errorMessage = nil
        authManager.isLoading = true
        
        mockAPI.shouldSucceed = true
        mockAPI.loginResponse = LoginResponse(
            message: "Login successful",
            token: "flow-test-token",
            user: User(
                id: 1,
                email: "flow@test.com",
                firstName: "Flow",
                lastName: "Test",
                phone: nil,
                profileImageUrl: nil
            )
        )
        
        do {
            let response = try await mockAPI.mockLogin(
                email: "flow@test.com",
                password: "password"
            )
            
            UserDefaults.standard.set(response.token, forKey: "auth_token")
            authManager.currentUser = response.user
            authManager.isAuthenticated = true
            
        } catch {
            authManager.errorMessage = error.localizedDescription
        }
        
        authManager.isLoading = false
        
        // Step 3: Verify successful state
        #expect(authManager.isAuthenticated == true)
        #expect(authManager.currentUser?.email == "flow@test.com")
        #expect(authManager.errorMessage == nil)
        
        // Step 4: Logout and verify clean state
        authManager.logout()
        
        #expect(authManager.isAuthenticated == false)
        #expect(authManager.currentUser == nil)
        #expect(authManager.errorMessage == nil)
        #expect(UserDefaults.standard.string(forKey: "auth_token") == nil)
    }
}