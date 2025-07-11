//
//  AccountSettingsViewModel.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation
import UIKit

@MainActor
class AccountSettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var updateSuccess = false
    @Published var passwordChangeSuccess = false
    @Published var updatedUser: User?
    
    private let apiService = APIService.shared
    
    func updateProfile(firstName: String, lastName: String, email: String, phone: String?) async {
        isLoading = true
        errorMessage = ""
        showError = false
        updateSuccess = false
        
        do {
            let response = try await apiService.updateUserProfile(
                firstName: firstName,
                lastName: lastName,
                email: email,
                phone: phone
            )
            
            updatedUser = response.user
            updateSuccess = true
            print("Profile updated successfully")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Failed to update profile: \(error)")
        }
        
        isLoading = false
    }
    
    func changePassword(currentPassword: String, newPassword: String) async {
        isLoading = true
        errorMessage = ""
        showError = false
        passwordChangeSuccess = false
        
        do {
            try await apiService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            passwordChangeSuccess = true
            print("Password changed successfully")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Failed to change password: \(error)")
        }
        
        isLoading = false
    }
    
    func updateProfilePhoto(imageData: Data) async {
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            // Process image before upload
            let processedData = ImageProcessor.prepareImageForUpload(imageData) ?? imageData
            print("📸 ViewModel: Uploading photo, processed size: \(processedData.count) bytes")
            
            let response = try await apiService.uploadUserProfilePhoto(imageData: processedData)
            updatedUser = response.user
            print("✅ Profile photo uploaded successfully")
            print("📸 Updated user profile URL: \(response.user.profileImageUrl ?? "nil")")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ Failed to upload profile photo: \(error)")
        }
        
        isLoading = false
    }
    
    func deleteProfilePhoto() async {
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            let response = try await apiService.deleteUserProfilePhoto()
            updatedUser = response.user
            print("Profile photo deleted successfully")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("Failed to delete profile photo: \(error)")
        }
        
        isLoading = false
    }
}