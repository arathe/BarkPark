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
        let _ = print("🔍 UserProfileView: body called - isLoading: \(viewModel.isLoading), hasProfile: \(viewModel.userProfile != nil), error: \(viewModel.errorMessage ?? "none")")
        
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
                                    UserProfileDogCard(dog: dog)
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
                        
                        // Recent Check-ins Section
                        if !profile.recentCheckIns.isEmpty {
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                                Text("Recent Visits")
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                                    .padding(.horizontal)
                                
                                ForEach(profile.recentCheckIns) { checkIn in
                                    CheckInCard(checkIn: checkIn)
                                        .padding(.horizontal)
                                }
                            }
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
            } else {
                // No loading, no profile, no error - this is the blank state
                Text("No data loaded")
                    .onAppear {
                        print("🔍 UserProfileView: Blank state - no loading, no profile, no error")
                    }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            print("🔍 UserProfileView: onAppear called with userId: \(userId)")
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
struct UserProfileDogCard: View {
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
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                } placeholder: {
                    RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
                        .fill(BarkParkDesign.Colors.dogSecondary.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
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
        .cornerRadius(BarkParkDesign.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Check-in Card Component
struct CheckInCard: View {
    let checkIn: UserProfileCheckIn
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            // Park Icon
            Circle()
                .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "tree.fill")
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                )
            
            // Check-in Info
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                Text(checkIn.parkName)
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text(checkIn.parkAddress)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .lineLimit(1)
                
                HStack(spacing: BarkParkDesign.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(formatVisitTime(checkIn))
                        .font(BarkParkDesign.Typography.caption)
                }
                .foregroundColor(BarkParkDesign.Colors.accent)
            }
            
            Spacer()
            
            // Dogs count if any
            if !checkIn.dogsPresent.isEmpty {
                VStack {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 16))
                        .foregroundColor(BarkParkDesign.Colors.dogSecondary)
                    Text("\(checkIn.dogsPresent.count)")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
            }
        }
        .padding(BarkParkDesign.Spacing.md)
        .background(BarkParkDesign.Colors.cardBackground)
        .cornerRadius(BarkParkDesign.CornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatVisitTime(_ checkIn: UserProfileCheckIn) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let checkInDate = formatter.date(from: checkIn.checkedInAt) else {
            return "Unknown time"
        }
        
        let displayFormatter = DateFormatter()
        
        if checkIn.checkedOutAt != nil {
            // Visit completed
            if let checkOutDate = formatter.date(from: checkIn.checkedOutAt!) {
                let duration = checkOutDate.timeIntervalSince(checkInDate)
                let hours = Int(duration) / 3600
                let minutes = (Int(duration) % 3600) / 60
                
                if hours > 0 {
                    return "\(hours)h \(minutes)m visit"
                } else {
                    return "\(minutes)m visit"
                }
            }
        } else {
            // Still checked in
            return "Currently there"
        }
        
        // Fallback
        displayFormatter.dateStyle = .short
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: checkInDate)
    }
}

#Preview {
    NavigationView {
        UserProfileView(userId: 1)
            .onAppear {
                print("🔍 Preview: UserProfileView appeared")
            }
    }
}