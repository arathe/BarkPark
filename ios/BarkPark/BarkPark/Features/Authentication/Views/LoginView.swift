//
//  LoginView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: BarkParkDesign.Spacing.lg) {
                    // Header
                    VStack(spacing: BarkParkDesign.Spacing.sm) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        
                        Text("Welcome Back")
                            .font(BarkParkDesign.Typography.largeTitle)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Text("Sign in to your account")
                            .font(BarkParkDesign.Typography.subheadline)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    .padding(.top, BarkParkDesign.Spacing.xl)
                    
                    // Form
                    VStack(spacing: BarkParkDesign.Spacing.md) {
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
                        }
                        
                        // Error Message
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.error)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Login Button
                        Button {
                            Task {
                                await authManager.login(email: email, password: password)
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
                                Text(authManager.isLoading ? "Signing In..." : "Sign In")
                            }
                        }
                        .barkParkButton()
                        .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    }
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
                    
                    Spacer()
                }
            }
            .navigationTitle("Sign In")
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
    LoginView()
        .environmentObject(AuthenticationManager())
}