//
//  UserProfileView.swift
//  BarkPark
//
//  Created by Assistant on 6/17/25.
//

import SwiftUI

struct UserProfileView: View {
    let userId: Int
    @StateObject private var viewModel = UserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = viewModel.userProfile {
                ScrollView {
                    VStack(spacing: BarkParkDesign.Spacing.lg) {
                        // User Header Section
                        VStack(spacing: BarkParkDesign.Spacing.md) {
                            // Profile Image
                            if let imageUrl = profile.user.profileImageUrl, !imageUrl.isEmpty {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 100))
                                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            }
                            
                            // User Name
                            Text(profile.user.fullName)
                                .font(BarkParkDesign.Typography.title)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            // Member Since
                            if let createdAt = profile.user.createdAt {
                                Text("Member since \(formattedDate(createdAt))")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                        }
                        .padding(.top, BarkParkDesign.Spacing.lg)
                        
                        // Dogs Section
                        if !profile.dogs.isEmpty {
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                                Text("Dogs")
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                    .padding(.horizontal)
                                
                                ForEach(profile.dogs) { dog in
                                    DogCard(dog: dog)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            VStack(spacing: BarkParkDesign.Spacing.sm) {
                                Image(systemName: "pawprint")
                                    .font(.system(size: 40))
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText.opacity(0.5))
                                
                                Text("No dogs yet")
                                    .font(BarkParkDesign.Typography.body)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                            .padding(.vertical, BarkParkDesign.Spacing.xl)
                        }
                    }
                    .padding(.bottom, BarkParkDesign.Spacing.xl)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: BarkParkDesign.Spacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(BarkParkDesign.Colors.warning)
                    
                    Text("Error")
                        .font(BarkParkDesign.Typography.headline)
                    
                    Text(error)
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            Task {
                await viewModel.fetchUserProfile(userId: userId)
            }
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        
        return "Unknown"
    }
}

// MARK: - Dog Card Component
struct DogCard: View {
    let dog: UserProfileDog
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            // Dog Image
            if let imageUrl = dog.profileImageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.md))
                } placeholder: {
                    RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.md)
                        .fill(BarkParkDesign.Colors.dogSecondary.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.md)
                    .fill(BarkParkDesign.Colors.dogSecondary.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    )
            }
            
            // Dog Info
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                Text(dog.name)
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                HStack(spacing: BarkParkDesign.Spacing.xs) {
                    if let breed = dog.breed {
                        Text(breed)
                            .font(BarkParkDesign.Typography.callout)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    
                    if let age = dog.age, age > 0 {
                        Text("•")
                            .font(BarkParkDesign.Typography.callout)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text("\(age) \(age == 1 ? "year" : "years") old")
                            .font(BarkParkDesign.Typography.callout)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                
                if let gender = dog.gender {
                    HStack(spacing: BarkParkDesign.Spacing.xs) {
                        Image(systemName: gender.lowercased() == "male" ? "♂" : "♀")
                            .font(BarkParkDesign.Typography.caption)
                        Text(gender.capitalized)
                            .font(BarkParkDesign.Typography.caption)
                    }
                    .foregroundColor(BarkParkDesign.Colors.accent)
                }
            }
            
            Spacer()
        }
        .padding(BarkParkDesign.Spacing.md)
        .background(BarkParkDesign.Colors.cardBackground)
        .cornerRadius(BarkParkDesign.CornerRadius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        UserProfileView(userId: 1)
    }
}