//
//  MyDogsView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct MyDogsView: View {
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingAddDog = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: BarkParkDesign.Spacing.md) {
                if dogProfileViewModel.dogs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(dogProfileViewModel.dogs) { dog in
                        NavigationLink(destination: DogDetailView(dog: dog)
                            .environmentObject(dogProfileViewModel)
                            .environmentObject(authManager)) {
                                DogCard(
                                    dog: dog,
                                    role: dog.currentUserRole,
                                    isPending: dogProfileViewModel.isPendingInvite(for: dog)
                                )
                                .accessibility(identifier: "dogCard")
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(dogProfileViewModel.isPendingInvite(for: dog))
                    }
                }
            }
            .padding(BarkParkDesign.Spacing.md)
        }
        .navigationTitle("My Dogs")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddDog = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
            }
            
            // Add Skip button for new users who haven't added any dogs yet
            if authManager.isNewUser && dogProfileViewModel.dogs.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        authManager.clearNewUserFlag()
                    }
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
            }
        }
        .refreshable {
            dogProfileViewModel.loadDogs()
        }
        .sheet(isPresented: $showingAddDog) {
            AddDogView()
                .environmentObject(dogProfileViewModel)
                .environmentObject(authManager)
                .onDisappear {
                    // If this was a new user adding their first dog, clear the flag
                    if authManager.isNewUser && !dogProfileViewModel.dogs.isEmpty {
                        authManager.clearNewUserFlag()
                    }
                }
        }
        .onAppear {
            print("📱 MyDogsView: onAppear called")
            print("📱 MyDogsView: Current dogs count: \(dogProfileViewModel.dogs.count)")
            print("📱 MyDogsView: Is loading: \(dogProfileViewModel.isLoading)")
            print("📱 MyDogsView: Error message: \(dogProfileViewModel.errorMessage ?? "none")")
            // Load dogs when view appears
            dogProfileViewModel.loadDogs()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Spacer()
            
            Image(systemName: "pawprint.fill")
                .font(.system(size: 80))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text(authManager.isNewUser ? "Welcome to BarkPark!" : "No Dogs Yet")
                    .font(BarkParkDesign.Typography.title)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text(authManager.isNewUser ? "Let's add your first furry friend to get started!" : "Add your first furry friend to get started!")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Your First Dog") {
                showingAddDog = true
            }
            .barkParkButton()
            .padding(.top, BarkParkDesign.Spacing.md)
            
            Spacer()
        }
        .padding(BarkParkDesign.Spacing.lg)
    }
}

struct DogCard: View {
    let dog: Dog
    let role: DogOwnershipRole?
    let isPending: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
            // Dog Photo and Basic Info
            HStack(spacing: BarkParkDesign.Spacing.md) {
                // Profile Photo
                AsyncImage(url: dog.profileImageUrl.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 40))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                        .frame(width: 80, height: 80)
                        .background(BarkParkDesign.Colors.tertiaryBackground)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 2)
                )
                
                // Dog Info
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                    Text(dog.name)
                        .font(BarkParkDesign.Typography.title2)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text(dog.breed ?? "Mixed Breed")
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)

                    if let role {
                        Text(role.displayName)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            .padding(.horizontal, BarkParkDesign.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(BarkParkDesign.Colors.dogPrimary.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: BarkParkDesign.Spacing.sm) {
                        Text("\(dog.computedAge) years old")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text(dog.displayGender)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text(dog.displaySize)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: BarkParkDesign.Spacing.lg) {
                StatItem(title: "Energy", value: dog.displayEnergyLevel)
                StatItem(title: "Training", value: dog.displayTrainingLevel)
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                    SocialChip(kind: .dogs, score: dog.friendlinessDogs)
                    SocialChip(kind: .people, score: dog.friendlinessPeople)
                }
            }
            
            // Bio (if available)
            if let bio = dog.bio, !bio.isEmpty {
                Text(bio)
                    .font(BarkParkDesign.Typography.callout)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                    .lineLimit(3)
            }

            if dog.owners.count > 1 {
                Text("Shared with \(dog.owners.count) members")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }

            if isPending {
                Text("Access pending approval")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    .padding(.top, BarkParkDesign.Spacing.xs)
            }
        }
        .padding(BarkParkDesign.Spacing.md)
        .barkParkCard()
        .overlay(
            RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
                .stroke(isPending ? BarkParkDesign.Colors.dogPrimary.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .opacity(isPending ? 0.85 : 1.0)
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.xs) {
            Text(title)
                .font(BarkParkDesign.Typography.caption)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)

            Text(value)
                .font(BarkParkDesign.Typography.caption2)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
                .fontWeight(.medium)
        }
    }
}

struct SocialChip: View {
    enum Kind {
        case dogs
        case people
    }

    let kind: Kind
    let score: Int

    private var iconName: String {
        switch kind {
        case .dogs:
            return "pawprint.fill"
        case .people:
            return "person.2.fill"
        }
    }

    private var labelText: String {
        switch kind {
        case .dogs:
            return "Dogs"
        case .people:
            return "People"
        }
    }

    var body: some View {
        Label {
            Text("\(labelText) \(score)/5")
                .font(BarkParkDesign.Typography.caption2)
        } icon: {
            Image(systemName: iconName)
        }
        .padding(.horizontal, BarkParkDesign.Spacing.sm)
        .padding(.vertical, BarkParkDesign.Spacing.xs)
        .background(BarkParkDesign.Colors.dogPrimary.opacity(0.15))
        .foregroundColor(BarkParkDesign.Colors.primaryText)
        .clipShape(Capsule())
    }
}

#Preview {
    MyDogsView()
        .environmentObject(DogProfileViewModel())
        .environmentObject(AuthenticationManager())
}