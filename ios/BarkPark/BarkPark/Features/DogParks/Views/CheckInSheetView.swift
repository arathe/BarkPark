//
//  CheckInSheetView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import SwiftUI

struct CheckInSheetView: View {
    let park: DogPark
    let onCheckIn: ([Int]) -> Void
    let onCancel: () -> Void
    
    @StateObject private var dogProfileViewModel = DogProfileViewModel()
    @State private var selectedDogIds: Set<Int> = []
    @State private var isCheckingIn = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                    Text("Check In to \(park.name)")
                        .font(BarkParkDesign.Typography.title2)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text("Select which dogs you're bringing to the park (optional)")
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                .padding(.horizontal, BarkParkDesign.Spacing.md)
                
                // Dogs list
                if dogProfileViewModel.dogs.isEmpty {
                    emptyStateView
                } else {
                    dogsList
                }
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(isCheckingIn)
                }
            }
            .task {
                await dogProfileViewModel.loadDogs()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: BarkParkDesign.Spacing.md) {
            Image(systemName: "pawprint")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.6))
            
            Text("No Dogs Added")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Text("You can still check in without selecting dogs, or add a dog profile first.")
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BarkParkDesign.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(BarkParkDesign.Spacing.lg)
    }
    
    private var dogsList: some View {
        ScrollView {
            LazyVStack(spacing: BarkParkDesign.Spacing.sm) {
                ForEach(dogProfileViewModel.dogs) { dog in
                    DogCheckInCard(
                        dog: dog,
                        isSelected: selectedDogIds.contains(dog.id),
                        onToggle: {
                            if selectedDogIds.contains(dog.id) {
                                selectedDogIds.remove(dog.id)
                            } else {
                                selectedDogIds.insert(dog.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, BarkParkDesign.Spacing.md)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: BarkParkDesign.Spacing.sm) {
            Button(action: {
                performCheckIn()
            }) {
                HStack {
                    if isCheckingIn {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "location.badge.plus")
                    }
                    
                    Text(isCheckingIn ? "Checking In..." : "Check In")
                }
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(BarkParkDesign.Spacing.md)
                .background(BarkParkDesign.Colors.dogPrimary)
                .cornerRadius(12)
            }
            .disabled(isCheckingIn)
            
            if !selectedDogIds.isEmpty {
                Text("Checking in with \(selectedDogIds.count) dog\(selectedDogIds.count == 1 ? "" : "s")")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
        }
        .padding(BarkParkDesign.Spacing.md)
    }
    
    private func performCheckIn() {
        isCheckingIn = true
        
        let dogIds = Array(selectedDogIds)
        onCheckIn(dogIds)
        
        // Add a small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingIn = false
        }
    }
}

// MARK: - Dog Check-in Card
struct DogCheckInCard: View {
    let dog: Dog
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: BarkParkDesign.Spacing.md) {
                // Dog photo
                AsyncImage(url: URL(string: dog.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.6))
                        .font(.title2)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Dog info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.name)
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    HStack {
                        if let breed = dog.breed {
                            Text(breed)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        
                        if dog.breed != nil {
                            Text("•")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        
                        Text("\(dog.computedAge) year\(dog.computedAge == 1 ? "" : "s") old")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.tertiaryText)
                    .font(.title2)
            }
            .padding(BarkParkDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? BarkParkDesign.Colors.dogPrimary.opacity(0.1) : BarkParkDesign.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? BarkParkDesign.Colors.dogPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CheckInSheetView(
        park: DogPark(
            id: 1,
            name: "Sample Park",
            description: "A great park for dogs",
            address: "123 Main St",
            latitude: 40.7128,
            longitude: -74.0060,
            amenities: ["Water", "Parking"],
            rules: "Keep dogs on leash",
            hoursOpen: "06:00:00",
            hoursClose: "20:00:00",
            createdAt: "2025-06-11T00:00:00Z",
            updatedAt: "2025-06-11T00:00:00Z",
            activityLevel: "low",
            currentVisitors: 5,
            distanceKm: 1.2
        ),
        onCheckIn: { _ in },
        onCancel: { }
    )
}