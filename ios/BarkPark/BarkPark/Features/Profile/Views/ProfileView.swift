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
    @StateObject private var parksViewModel = DogParksViewModel()
    @State private var showingPrivacySettings = false
    @State private var showingAccountSettings = false
    @State private var navigateToMyDogs = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Active check-in card at the top
                if let activeCheckIn = parksViewModel.currentActiveCheckIn {
                    ActiveCheckInCard(
                        checkIn: activeCheckIn,
                        parkName: parksViewModel.activeCheckInPark?.name ?? "Loading...",
                        onCheckOut: {
                            Task {
                                await parksViewModel.checkOutOfParkById(activeCheckIn.dogParkId)
                            }
                        }
                    )
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: activeCheckIn)
                }
                
                List {
                // User Info Section
                Section {
                    Button(action: {
                        showingAccountSettings = true
                    }) {
                        HStack(spacing: BarkParkDesign.Spacing.md) {
                            // Profile Image
                            if let user = authManager.currentUser,
                               let profileImageUrl = user.profileImageUrl,
                               !profileImageUrl.isEmpty,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 2)
                                )
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            }
                            
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
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        .padding(.vertical, BarkParkDesign.Spacing.sm)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
                    .environmentObject(authManager)
            }
            .onAppear {
                // Load dogs when profile appears
                dogProfileViewModel.loadDogs()
                
                // Load active check-ins
                Task {
                    await parksViewModel.loadActiveCheckIns()
                }
                
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