//
//  MyPackView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct MyPackView: View {
    @EnvironmentObject var dogProfileViewModel: DogProfileViewModel
    @State private var showingAddDog = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: BarkParkDesign.Spacing.md) {
                    if dogProfileViewModel.dogs.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(dogProfileViewModel.dogs) { dog in
                            DogCard(dog: dog)
                                .accessibility(identifier: "dogCard")
                        }
                    }
                }
                .padding(BarkParkDesign.Spacing.md)
            }
            .navigationTitle("My Pack")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddDog = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    }
                }
            }
            .refreshable {
                dogProfileViewModel.loadDogs()
            }
        }
        .sheet(isPresented: $showingAddDog) {
            AddDogView()
                .environmentObject(dogProfileViewModel)
        }
        .onAppear {
            print("📱 MyPackView: onAppear called")
            print("📱 MyPackView: Current dogs count: \(dogProfileViewModel.dogs.count)")
            print("📱 MyPackView: Is loading: \(dogProfileViewModel.isLoading)")
            print("📱 MyPackView: Error message: \(dogProfileViewModel.errorMessage ?? "none")")
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
                Text("No Dogs Yet")
                    .font(BarkParkDesign.Typography.title)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("Add your first furry friend to get started!")
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
                StatItem(title: "Social", value: "\(dog.friendlinessDogs)/5")
            }
            
            // Bio (if available)
            if let bio = dog.bio, !bio.isEmpty {
                Text(bio)
                    .font(BarkParkDesign.Typography.callout)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                    .lineLimit(3)
            }
        }
        .padding(BarkParkDesign.Spacing.md)
        .barkParkCard()
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

#Preview {
    MyPackView()
        .environmentObject(DogProfileViewModel())
}