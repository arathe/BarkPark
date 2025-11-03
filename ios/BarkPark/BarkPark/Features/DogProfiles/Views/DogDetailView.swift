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
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    @State private var showingShareSheet = false
    @State private var membershipActionInFlight = false
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private var currentDog: Dog {
        dogProfileViewModel.dogs.first(where: { $0.id == dog.id }) ?? dog
    }

    private var hasManagementActions: Bool {
        dogProfileViewModel.canManageMembers(dog: currentDog) ||
        dogProfileViewModel.canEdit(dog: currentDog) ||
        dogProfileViewModel.canDelete(dog: currentDog)
    }
    
    var body: some View {
        let dog = currentDog

        return ScrollView {
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.lg) {
                if dogProfileViewModel.isPendingInvite(for: dog) {
                    pendingInviteBanner(for: dog)
                }

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

                    if !dog.owners.isEmpty {
                        DetailSection(title: "Shared Access") {
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                                ForEach(dog.owners, id: \.self) { member in
                                    HStack(spacing: BarkParkDesign.Spacing.md) {
                                        AsyncImage(url: member.profileImageUrl.flatMap(URL.init)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(BarkParkDesign.Colors.tertiaryBackground)
                                                .overlay(
                                                    Text(member.initials)
                                                        .font(BarkParkDesign.Typography.caption)
                                                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                                )
                                        }
                                        .frame(width: 36, height: 36)
                                        .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.fullName)
                                                .font(BarkParkDesign.Typography.body)
                                                .foregroundColor(BarkParkDesign.Colors.primaryText)

                                            Text(member.displayRole)
                                                .font(BarkParkDesign.Typography.caption)
                                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                        }

                                        Spacer()

                                        if let badge = member.statusBadgeText {
                                            Text(badge)
                                                .font(BarkParkDesign.Typography.caption)
                                                .padding(.horizontal, BarkParkDesign.Spacing.sm)
                                                .padding(.vertical, 4)
                                                .background(BarkParkDesign.Colors.dogPrimary.opacity(0.12))
                                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Gallery (if available)
                    if !dog.galleryImages.isEmpty {
                        DetailSection(title: "Photo Gallery") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: BarkParkDesign.Spacing.md), count: 3), spacing: BarkParkDesign.Spacing.md) {
                                ForEach(dog.galleryImages, id: \.self) { imageUrl in
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                    } placeholder: {
                                        Rectangle()
                                            .foregroundColor(BarkParkDesign.Colors.tertiaryBackground)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: BarkParkDesign.Colors.dogPrimary))
                                            )
                                    }
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
                if hasManagementActions {
                    Menu {
                        if dogProfileViewModel.canManageMembers(dog: dog) {
                            Button {
                                showingShareSheet = true
                            } label: {
                                Label("Share Dog", systemImage: "person.2.circle")
                            }
                        }

                        if dogProfileViewModel.canEdit(dog: dog) {
                            Button {
                                showingEditSheet = true
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                        }

                        if dogProfileViewModel.canDelete(dog: dog) {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Dog", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDogView(dog: dog)
                .environmentObject(dogProfileViewModel)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareDogSheet(dog: dog)
                .environmentObject(dogProfileViewModel)
        }
        .alert("Delete \(dog.name)?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteDog()
            }
        } message: {
            Text("This will permanently delete \(dog.name)'s profile and all associated photos. This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: BarkParkDesign.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Deleting...")
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(.white)
                        }
                        .padding(BarkParkDesign.Spacing.lg)
                        .background(BarkParkDesign.Colors.tertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                    }
            }
        }
    }
    
    private func deleteDog() {
        let dog = currentDog
        guard dogProfileViewModel.canDelete(dog: dog) else { return }
        isDeleting = true

        Task {
            let success = await dogProfileViewModel.deleteDog(dog)
            isDeleting = false

            if success {
                dismiss()
            }
        }
    }

    private func pendingInviteBanner(for dog: Dog) -> some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            Text("Access Pending")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)

            Text("You're invited to help manage \(dog.name). Accept the invite to unlock editing and sharing controls.")
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: BarkParkDesign.Spacing.sm) {
                Button(action: { respondToInvite(for: dog, accept: true) }) {
                    if membershipActionInFlight {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Accept")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(membershipActionInFlight)
                .padding(.horizontal, BarkParkDesign.Spacing.lg)
                .padding(.vertical, BarkParkDesign.Spacing.sm)
                .background(BarkParkDesign.Colors.dogPrimary)
                .foregroundColor(.white)
                .clipShape(Capsule())

                Button(role: .destructive, action: { respondToInvite(for: dog, accept: false) }) {
                    Text("Decline")
                        .fontWeight(.semibold)
                }
                .disabled(membershipActionInFlight)
                .padding(.horizontal, BarkParkDesign.Spacing.lg)
                .padding(.vertical, BarkParkDesign.Spacing.sm)
                .background(BarkParkDesign.Colors.tertiaryBackground)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
                .clipShape(Capsule())
            }
        }
        .padding(BarkParkDesign.Spacing.md)
        .background(BarkParkDesign.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
        .padding(.horizontal, BarkParkDesign.Spacing.md)
        .padding(.top, BarkParkDesign.Spacing.md)
    }

    private func respondToInvite(for dog: Dog, accept: Bool) {
        guard let membershipId = dogProfileViewModel.membershipIdForCurrentUser(for: dog) else { return }
        membershipActionInFlight = true

        Task {
            let success = await dogProfileViewModel.respondToInvite(for: dog, membershipId: membershipId, accept: accept)
            membershipActionInFlight = false

            if success && !accept {
                dismiss()
            }
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

// MARK: - Preview Data
struct PreviewData {
    static let sampleDog: Dog = {
        let jsonString = """
        {
            "id": 1,
            "name": "Buddy",
            "breed": "Golden Retriever",
            "birthday": "2020-05-15",
            "age": 5,
            "weight": "65.5",
            "gender": "male",
            "sizeCategory": "large",
            "energyLevel": "high",
            "friendlinessDogs": 5,
            "friendlinessPeople": 4,
            "trainingLevel": "advanced",
            "favoriteActivities": ["fetch", "swimming", "hiking"],
            "isVaccinated": true,
            "isSpayedNeutered": true,
            "specialNeeds": null,
            "bio": "Buddy is a friendly and energetic Golden Retriever who loves to play fetch and swim.",
            "profileImageUrl": null,
            "galleryImages": [],
            "owners": [
                {
                    "id": 1,
                    "firstName": "Alex",
                    "lastName": "Rathe",
                    "role": "owner",
                    "status": "active",
                    "membershipId": 1
                }
            ],
            "currentUserRole": "owner",
            "createdAt": "2023-01-01T00:00:00.000Z",
            "updatedAt": "2023-01-01T00:00:00.000Z"
        }
        """
        let data = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(Dog.self, from: data)
    }()
}

#Preview {
    NavigationView {
        DogDetailView(dog: PreviewData.sampleDog)
            .environmentObject(DogProfileViewModel())
    }
}