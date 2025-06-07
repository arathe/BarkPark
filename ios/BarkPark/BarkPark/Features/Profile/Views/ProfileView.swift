//
//  ProfileView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
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
                
                // Settings Section
                Section("Settings") {
                    SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage your notifications")
                    SettingsRow(icon: "lock", title: "Privacy", subtitle: "Privacy settings")
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
}