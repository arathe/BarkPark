//
//  ProfileView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    @State private var showingPrivacySettings = false
    @State private var navigateToMyDogs = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack(spacing: BarkParkDesign.Spacing.md) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        
                        if let user = authManager.currentUser {
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                Text(user.fullName)
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                
                                Text(user.email)
                                    .font(BarkParkDesign.Typography.callout)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                }
                
                // My Dogs Section
                Section("My Dogs") {
                    NavigationLink(
                        destination: MyDogsView()
                            .environmentObject(dogProfileViewModel),
                        isActive: $navigateToMyDogs
                    ) {
                        HStack(spacing: BarkParkDesign.Spacing.md) {
                            Image(systemName: "pawprint.fill")
                                .font(.system(size: 20))
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                Text("Manage Your Dogs")
                                    .font(BarkParkDesign.Typography.callout)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                
                                Text("\(dogProfileViewModel.dogs.count) \(dogProfileViewModel.dogs.count == 1 ? "dog" : "dogs") in your pack")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        .padding(.vertical, BarkParkDesign.Spacing.xs)
                    }
                }
                
                // Settings Section
                Section("Settings") {
                    SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage your notifications")
                    
                    Button(action: {
                        showingPrivacySettings = true
                    }) {
                        SettingsRow(icon: "lock", title: "Privacy", subtitle: "Control your search visibility")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support", subtitle: "Get help")
                    SettingsRow(icon: "info.circle", title: "About", subtitle: "App information")
                }
                
                // Account Section
                Section("Account") {
                    Button {
                        authManager.logout()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(BarkParkDesign.Colors.error)
                            Text("Sign Out")
                                .foregroundColor(BarkParkDesign.Colors.error)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Load dogs when profile appears
                dogProfileViewModel.loadDogs()
                
                // For new users, automatically navigate to My Dogs
                if authManager.isNewUser {
                    // Use a small delay to ensure the navigation view is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToMyDogs = true
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                Text(title)
                    .font(BarkParkDesign.Typography.callout)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text(subtitle)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
        .padding(.vertical, BarkParkDesign.Spacing.xs)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DogProfileViewModel())
}