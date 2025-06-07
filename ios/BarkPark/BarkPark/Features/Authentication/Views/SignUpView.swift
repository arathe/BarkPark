//
//  SignUpView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: BarkParkDesign.Spacing.lg) {
                    // Header
                    VStack(spacing: BarkParkDesign.Spacing.sm) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        
                        Text("Join BarkPark")
                            .font(BarkParkDesign.Typography.largeTitle)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Text("Create your account")
                            .font(BarkParkDesign.Typography.subheadline)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    .padding(.top, BarkParkDesign.Spacing.xl)
                    
                    // Form
                    VStack(spacing: BarkParkDesign.Spacing.md) {
                        // Name Fields
                        HStack(spacing: BarkParkDesign.Spacing.sm) {
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                Text("First Name")
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                
                                TextField("First name", text: $firstName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                            }
                            
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                Text("Last Name")
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                
                                TextField("Last name", text: $lastName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                            Text("Email")
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                            Text("Password")
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter your password", text: $password)
                                } else {
                                    SecureField("Enter your password", text: $password)
                                }
                                
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("Password must be at least 6 characters")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                            Text("Confirm Password")
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm your password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm your password", text: $confirmPassword)
                                }
                                
                                Button {
                                    showConfirmPassword.toggle()
                                } label: {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.error)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.error)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Sign Up Button
                        Button {
                            Task {
                                await authManager.register(
                                    email: email,
                                    password: password,
                                    firstName: firstName,
                                    lastName: lastName
                                )
                                if authManager.isAuthenticated {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                Text(authManager.isLoading ? "Creating Account..." : "Create Account")
                            }
                        }
                        .barkParkButton()
                        .disabled(!isFormValid || authManager.isLoading)
                    }
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthenticationManager())
}