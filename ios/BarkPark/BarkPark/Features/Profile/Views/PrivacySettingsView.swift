//
//  PrivacySettingsView.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSearchable: Bool = true
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                            Text("Allow others to find me")
                                .font(BarkParkDesign.Typography.callout)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            Text("When enabled, other users can find you in search results when looking for friends")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isSearchable)
                            .disabled(isLoading)
                            .onChange(of: isSearchable) { newValue in
                                updatePrivacySetting(newValue)
                            }
                    }
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                } header: {
                    Text("Search Visibility")
                } footer: {
                    Text("Privacy settings help you control how other users can interact with your profile. You can always change these settings later.")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            Text("How Privacy Works")
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            PrivacyInfoRow(
                                icon: "eye.slash",
                                title: "Search Hidden",
                                description: "When disabled, other users won't see you in search results"
                            )
                            
                            PrivacyInfoRow(
                                icon: "qrcode",
                                title: "QR Code Always Works",
                                description: "You can still connect via QR code regardless of this setting"
                            )
                            
                            PrivacyInfoRow(
                                icon: "person.2",
                                title: "Existing Friends Unaffected",
                                description: "Your current friends can always see your profile"
                            )
                        }
                    }
                    .padding(.vertical, BarkParkDesign.Spacing.sm)
                } header: {
                    Text("About Privacy Settings")
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCurrentSetting()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Updating...")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .padding(.top, BarkParkDesign.Spacing.sm)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(BarkParkDesign.Colors.background.opacity(0.8))
                }
            }
        }
    }
    
    private func loadCurrentSetting() {
        if let user = authManager.currentUser {
            isSearchable = user.isSearchable ?? true
        }
    }
    
    private func updatePrivacySetting(_ newValue: Bool) {
        guard let user = authManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let updatedUser = try await APIService.shared.updateUserProfile(
                    firstName: user.firstName,
                    lastName: user.lastName,
                    phone: user.phone,
                    isSearchable: newValue
                )
                
                await MainActor.run {
                    authManager.updateCurrentUser(updatedUser.user)
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    isSearchable = !newValue // Revert the toggle
                    errorMessage = "Failed to update privacy setting. Please try again."
                    showingError = true
                }
            }
        }
    }
}

struct PrivacyInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                Text(title)
                    .font(BarkParkDesign.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text(description)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    PrivacySettingsView()
        .environmentObject(AuthenticationManager())
}