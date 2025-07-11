//
//  AccountSettingsView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = AccountSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImageData: Data?
    @State private var profileImage: UIImage?
    
    @State private var showingChangePassword = false
    @State private var showingDeleteAccount = false
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Photo Section
                Section("Profile Photo") {
                    HStack {
                        // Photo Display
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 2)
                                )
                        } else if let currentUser = authManager.currentUser,
                                  let profileImageUrl = currentUser.profileImageUrl,
                                  !profileImageUrl.isEmpty {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 2)
                            )
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                                .frame(width: 80, height: 80)
                                .background(BarkParkDesign.Colors.tertiaryBackground)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 2)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                Text(profileImage == nil && authManager.currentUser?.profileImageUrl == nil ? "Add Profile Photo" : "Change Photo")
                                    .font(BarkParkDesign.Typography.callout)
                                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            }
                            
                            if profileImage != nil || authManager.currentUser?.profileImageUrl != nil {
                                Button("Remove Photo") {
                                    resetPhoto()
                                }
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.error)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                // Profile Information Section
                Section("Profile Information") {
                    HStack {
                        Text("First Name")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .frame(width: 100, alignment: .leading)
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                    }
                    
                    HStack {
                        Text("Last Name")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .frame(width: 100, alignment: .leading)
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                    }
                    
                    HStack {
                        Text("Email")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .frame(width: 100, alignment: .leading)
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    HStack {
                        Text("Phone")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .frame(width: 100, alignment: .leading)
                        TextField("Phone (optional)", text: $phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }
                
                // Account Security Section
                Section("Account Security") {
                    Button(action: {
                        showingChangePassword = true
                    }) {
                        HStack {
                            Text("Change Password")
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                    }
                }
                
                // Danger Zone Section
                Section {
                    Button(action: {
                        showingDeleteAccount = true
                    }) {
                        Text("Delete Account")
                            .foregroundColor(BarkParkDesign.Colors.error)
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting your account is permanent and cannot be undone.")
                        .font(BarkParkDesign.Typography.caption)
                }
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!hasChanges || viewModel.isLoading)
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView()
            }
            .alert("Delete Account", isPresented: $showingDeleteAccount) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // TODO: Implement account deletion
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
            .onAppear {
                loadUserData()
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        print("📸 Photo selected, loading data...")
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            profileImageData = data
                            profileImage = UIImage(data: data)
                            print("📸 Photo data loaded: \(data.count) bytes")
                        } else {
                            print("❌ Failed to load photo data")
                        }
                    }
                }
            }
        }
    }
    
    private var hasChanges: Bool {
        guard let currentUser = authManager.currentUser else { return false }
        
        return firstName != currentUser.firstName ||
               lastName != currentUser.lastName ||
               email != currentUser.email ||
               phone != (currentUser.phone ?? "") ||
               profileImageData != nil
    }
    
    private func loadUserData() {
        guard let currentUser = authManager.currentUser else { return }
        
        firstName = currentUser.firstName
        lastName = currentUser.lastName
        email = currentUser.email
        phone = currentUser.phone ?? ""
    }
    
    private func saveChanges() async {
        print("💾 Starting save changes...")
        
        var photoUploadSuccess = true
        
        // First update profile photo if changed
        if let profileImageData = profileImageData {
            print("📸 Uploading profile photo: \(profileImageData.count) bytes")
            await viewModel.updateProfilePhoto(imageData: profileImageData)
            
            // Check if photo upload was successful
            if viewModel.showError {
                print("❌ Photo upload failed, aborting save")
                return
            }
        } else {
            print("📸 No profile photo to upload")
        }
        
        // Then update profile information
        print("📝 Updating profile information")
        await viewModel.updateProfile(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone.isEmpty ? nil : phone
        )
        
        if viewModel.updateSuccess {
            print("✅ Profile update successful")
            // Update the current user in AuthenticationManager
            if let updatedUser = viewModel.updatedUser {
                authManager.updateCurrentUser(updatedUser)
            }
            dismiss()
        } else {
            print("❌ Profile update failed")
        }
    }
    
    private func resetPhoto() {
        selectedPhoto = nil
        profileImageData = nil
        profileImage = nil
        
        Task {
            await viewModel.deleteProfilePhoto()
            if let updatedUser = viewModel.updatedUser {
                authManager.updateCurrentUser(updatedUser)
            }
        }
    }
}

struct ChangePasswordView: View {
    @StateObject private var viewModel = AccountSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Password") {
                    SecureField("Current Password", text: $currentPassword)
                }
                
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                Section {
                    Text("Password must be at least 8 characters long")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await changePassword()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidInput || viewModel.isLoading)
                }
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.passwordChangeSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully.")
            }
        }
    }
    
    private var isValidInput: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 8 &&
        newPassword == confirmPassword
    }
    
    private func changePassword() async {
        await viewModel.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword
        )
    }
}

#Preview {
    AccountSettingsView()
        .environmentObject(AuthenticationManager())
}