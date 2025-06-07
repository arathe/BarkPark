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
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for existing token on init
        checkAuthenticationStatus()
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginResponse = try await apiService.login(email: email, password: password)
            
            // Store token
            UserDefaults.standard.set(loginResponse.token, forKey: "auth_token")
            
            // Set current user
            currentUser = loginResponse.user
            isAuthenticated = true
        } catch {
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
            // Token might be expired, remove it
            UserDefaults.standard.removeObject(forKey: "auth_token")
            isAuthenticated = false
            currentUser = nil
        }
    }
}