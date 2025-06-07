//
//  DogDetailView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct DogDetailView: View {
    let dog: Dog
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.lg) {
                // Header with Photo
                VStack(spacing: BarkParkDesign.Spacing.md) {
                    AsyncImage(url: dog.profileImageUrl.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                            .frame(width: 150, height: 150)
                            .background(BarkParkDesign.Colors.tertiaryBackground)
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 3)
                    )
                    
                    VStack(spacing: BarkParkDesign.Spacing.xs) {
                        Text(dog.name)
                            .font(BarkParkDesign.Typography.largeTitle)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Text(dog.breed ?? "Mixed Breed")
                            .font(BarkParkDesign.Typography.title3)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, BarkParkDesign.Spacing.lg)
                
                // Quick Stats
                HStack(spacing: BarkParkDesign.Spacing.lg) {
                    Spacer()
                    DetailStatItem(title: "Age", value: "\(dog.computedAge) years")
                    DetailStatItem(title: "Gender", value: dog.displayGender)
                    DetailStatItem(title: "Size", value: dog.displaySize)
                    Spacer()
                }
                .padding(.vertical, BarkParkDesign.Spacing.md)
                .background(BarkParkDesign.Colors.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.lg) {
                    // Bio
                    if let bio = dog.bio, !bio.isEmpty {
                        DetailSection(title: "About \(dog.name)") {
                            Text(bio)
                                .font(BarkParkDesign.Typography.body)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                        }
                    }
                    
                    // Physical Info
                    DetailSection(title: "Physical Info") {
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            if let weight = dog.weight {
                                DetailRow(label: "Weight", value: String(format: "%.1f lbs", weight))
                            }
                            DetailRow(label: "Size Category", value: dog.displaySize)
                            DetailRow(label: "Energy Level", value: dog.displayEnergyLevel)
                        }
                    }
                    
                    // Personality
                    DetailSection(title: "Personality") {
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            DetailRow(label: "Friendliness with Dogs", value: "\(dog.friendlinessDogs)/5")
                            DetailRow(label: "Friendliness with People", value: "\(dog.friendlinessPeople)/5")
                            DetailRow(label: "Training Level", value: dog.displayTrainingLevel)
                            
                            if !dog.favoriteActivities.isEmpty {
                                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                    Text("Favorite Activities")
                                        .font(BarkParkDesign.Typography.headline)
                                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: BarkParkDesign.Spacing.xs) {
                                        ForEach(dog.favoriteActivities, id: \.self) { activity in
                                            Text(activity.capitalized)
                                                .font(BarkParkDesign.Typography.caption)
                                                .padding(.horizontal, BarkParkDesign.Spacing.sm)
                                                .padding(.vertical, BarkParkDesign.Spacing.xs)
                                                .background(BarkParkDesign.Colors.dogPrimary.opacity(0.1))
                                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                                .padding(.top, BarkParkDesign.Spacing.sm)
                            }
                        }
                    }
                    
                    // Health
                    DetailSection(title: "Health Info") {
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            DetailRow(label: "Vaccinated", value: dog.isVaccinated ? "Yes" : "No")
                            DetailRow(label: "Spayed/Neutered", value: dog.isSpayedNeutered ? "Yes" : "No")
                            
                            if let specialNeeds = dog.specialNeeds, !specialNeeds.isEmpty {
                                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                    Text("Special Needs")
                                        .font(BarkParkDesign.Typography.headline)
                                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                                    
                                    Text(specialNeeds)
                                        .font(BarkParkDesign.Typography.body)
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                }
                                .padding(.top, BarkParkDesign.Spacing.sm)
                            }
                        }
                    }
                    
                    // Gallery (if available)
                    if !dog.galleryImages.isEmpty {
                        DetailSection(title: "Photo Gallery") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: BarkParkDesign.Spacing.sm) {
                                ForEach(dog.galleryImages, id: \.self) { imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .foregroundColor(BarkParkDesign.Colors.tertiaryBackground)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: BarkParkDesign.Colors.dogPrimary))
                                            )
                                    }
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.small))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, BarkParkDesign.Spacing.md)
            }
        }
        .navigationTitle(dog.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDogView(dog: dog)
                .environmentObject(DogProfileViewModel())
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
            Text(title)
                .font(BarkParkDesign.Typography.title2)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            content
        }
        .padding(BarkParkDesign.Spacing.md)
        .barkParkCard()
    }
}

struct DetailStatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.xs) {
            Text(value)
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Text(title)
                .font(BarkParkDesign.Typography.caption)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(BarkParkDesign.Typography.callout)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(BarkParkDesign.Typography.callout)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
    }
}

#Preview {
    NavigationView {
        DogDetailView(dog: Dog(
            id: 1,
            name: "Buddy",
            breed: "Golden Retriever",
            birthday: "2020-05-15",
            age: 5,
            weight: 65.5,
            gender: "male",
            sizeCategory: "large",
            energyLevel: "high",
            friendlinessDogs: 5,
            friendlinessPeople: 4,
            trainingLevel: "advanced",
            favoriteActivities: ["fetch", "swimming", "hiking"],
            isVaccinated: true,
            isSpayedNeutered: true,
            specialNeeds: nil,
            bio: "Buddy is a friendly and energetic Golden Retriever who loves to play fetch and swim.",
            profileImageUrl: nil,
            galleryImages: [],
            userId: 1,
            createdAt: "2023-01-01T00:00:00.000Z",
            updatedAt: "2023-01-01T00:00:00.000Z"
        ))
    }
}