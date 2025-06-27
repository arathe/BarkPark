import Foundation
import SwiftUI

@MainActor
class PasswordResetViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var resetToken: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    @Published var showResetTokenView: Bool = false
    @Published var resetComplete: Bool = false
    
    private let apiService = APIService.shared
    
    // Email validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // Password validation
    var isValidPassword: Bool {
        newPassword.count >= 6
    }
    
    var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    var canSubmitReset: Bool {
        !resetToken.isEmpty && isValidPassword && passwordsMatch
    }
    
    func requestPasswordReset() async {
        guard isValidEmail else {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            let response = try await apiService.requestPasswordReset(email: email)
            successMessage = response.message
            showResetTokenView = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to send reset email. Please try again."
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard canSubmitReset else {
            if resetToken.isEmpty {
                errorMessage = "Please enter the reset code from your email"
            } else if !isValidPassword {
                errorMessage = "Password must be at least 6 characters"
            } else if !passwordsMatch {
                errorMessage = "Passwords do not match"
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.resetPassword(
                token: resetToken,
                newPassword: newPassword
            )
            
            // Store the new auth token
            UserDefaults.standard.set(response.token, forKey: "auth_token")
            
            // Authentication is handled by storing the token
            // The app will check for token on next launch
            
            successMessage = response.message
            resetComplete = true
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to reset password. Please try again."
        }
        
        isLoading = false
    }
    
    func verifyToken() async {
        guard !resetToken.isEmpty else { return }
        
        do {
            let response = try await apiService.verifyResetToken(token: resetToken)
            if response.valid {
                // Token is valid, show email for confirmation
                email = response.email
            } else {
                errorMessage = "Invalid or expired reset code"
            }
        } catch {
            // Don't show error for verification, let them try to reset
        }
    }
    
    func reset() {
        email = ""
        resetToken = ""
        newPassword = ""
        confirmPassword = ""
        errorMessage = nil
        successMessage = nil
        showResetTokenView = false
        resetComplete = false
    }
}