//
//  AuthenticationManager.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isNewUser = false
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for existing token on init
        checkAuthenticationStatus()
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        print("🔐 AuthenticationManager: Starting login for \(email)")
        
        do {
            let loginResponse = try await apiService.login(email: email, password: password)
            
            // Store token
            print("🔐 AuthenticationManager: Storing token: \(String(loginResponse.token.prefix(20)))...")
            UserDefaults.standard.set(loginResponse.token, forKey: "auth_token")
            
            // Set current user
            currentUser = loginResponse.user
            isAuthenticated = true
            print("🔐 AuthenticationManager: Login successful for user: \(loginResponse.user.email)")
        } catch {
            print("🔐 AuthenticationManager: Login failed with error: \(error)")
            print("🔐 AuthenticationManager: Error localized description: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerResponse = try await apiService.register(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            
            // Store token
            UserDefaults.standard.set(registerResponse.token, forKey: "auth_token")
            
            // Set current user
            currentUser = registerResponse.user
            isAuthenticated = true
            isNewUser = true // Flag to show dog creation prompt
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }

    func checkAuthenticationStatus() {
        let token = UserDefaults.standard.string(forKey: "auth_token")
        if token != nil {
            isAuthenticated = true
            Task {
                await fetchCurrentUser()
            }
        }
    }

    private func fetchCurrentUser() async {
        do {
            let user = try await apiService.getCurrentUser()
            currentUser = user
            isAuthenticated = true
        } catch {
            if let apiError = error as? APIError,
               case .authenticationFailed = apiError {
                // Token invalid or expired
                UserDefaults.standard.removeObject(forKey: "auth_token")
                isAuthenticated = false
                currentUser = nil
            } else {
                // Keep user logged in for other errors (e.g., network issues)
                print("⚠️ fetchCurrentUser error: \(error)")
            }
        }
    }
    
    func updateCurrentUser(_ user: User) {
        currentUser = user
    }
    
    func clearNewUserFlag() {
        isNewUser = false
    }
}