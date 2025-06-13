//
//  ParkDetailView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import SwiftUI
import MapKit

struct ParkDetailView: View {
    let park: DogPark
    let isCheckedIn: Bool
    let onCheckIn: ([Int]) async -> Bool
    let onCheckOut: () async -> Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ParkDetailViewModel()
    @State private var showingCheckInSheet = false
    @State private var showingCheckOutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.lg) {
                    // Header with map preview
                    headerSection
                    
                    // Activity and basic info
                    activitySection
                    
                    // Park details
                    detailsSection
                    
                    // Amenities
                    if !park.amenities.isEmpty {
                        amenitiesSection
                    }
                    
                    // Rules
                    if let rules = park.rules, !rules.isEmpty {
                        rulesSection
                    }
                    
                    // Hours
                    hoursSection
                    
                    // Action button
                    actionButton
                }
                .padding(BarkParkDesign.Spacing.md)
            }
            .navigationTitle(park.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadParkDetails(parkId: park.id)
            }
            .sheet(isPresented: $showingCheckInSheet) {
                CheckInSheetView(
                    park: park,
                    onCheckIn: onCheckIn,
                    onCancel: {
                        showingCheckInSheet = false
                    }
                )
            }
            .alert("Check Out", isPresented: $showingCheckOutConfirmation) {
                Button("Check Out", role: .destructive) {
                    Task {
                        let success = await onCheckOut()
                        if success {
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to check out of \(park.name)?")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            // Mini map
            Map(initialPosition: .region(MKCoordinateRegion(
                center: park.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))) {
                Marker(park.name, coordinate: park.coordinate)
                    .tint(park.activityColorSwiftUI)
            }
            .frame(height: 120)
            .cornerRadius(12)
            .allowsHitTesting(false)
            
            // Address
            Text(park.address)
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            HStack {
                Text("Current Activity")
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack(spacing: BarkParkDesign.Spacing.md) {
                // Activity level
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Level")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(park.activityColorSwiftUI)
                            .frame(width: 12, height: 12)
                        
                        Text(park.activityLevelText)
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                    }
                }
                
                Spacer()
                
                // Current visitors
                if let visitors = viewModel.currentVisitors ?? park.currentVisitors {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current Visitors")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text("\(visitors)")
                            .font(BarkParkDesign.Typography.headline)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                    }
                }
            }
            .padding(BarkParkDesign.Spacing.md)
            .background(BarkParkDesign.Colors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            Text("About")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            if let description = park.description, !description.isEmpty {
                Text(description)
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.leading)
            } else {
                Text("No description available for this park.")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                    .italic()
            }
        }
    }
    
    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            Text("Amenities")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: BarkParkDesign.Spacing.sm) {
                ForEach(park.amenities, id: \.self) { amenity in
                    HStack(spacing: 8) {
                        Image(systemName: amenityIcon(for: amenity))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            .frame(width: 20)
                        
                        Text(amenity)
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            Text("Park Rules")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Text(park.rules!)
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
            Text("Hours")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            HStack {
                if let isOpen = park.isOpen {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isOpen ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(isOpen ? "Open" : "Closed")
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(isOpen ? .green : .red)
                    }
                }
                
                Spacer()
                
                Text(park.displayHours)
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
            .padding(BarkParkDesign.Spacing.md)
            .background(BarkParkDesign.Colors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var actionButton: some View {
        VStack(spacing: BarkParkDesign.Spacing.md) {
            if isCheckedIn {
                Button(action: {
                    showingCheckOutConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Check Out")
                    }
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(BarkParkDesign.Spacing.md)
                    .background(Color.red)
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    showingCheckInSheet = true
                }) {
                    HStack {
                        Image(systemName: "location.badge.plus")
                        Text("Check In")
                    }
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(BarkParkDesign.Spacing.md)
                    .background(BarkParkDesign.Colors.dogPrimary)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func amenityIcon(for amenity: String) -> String {
        let lowercased = amenity.lowercased()
        
        if lowercased.contains("water") {
            return "drop.fill"
        } else if lowercased.contains("parking") {
            return "car.fill"
        } else if lowercased.contains("fence") || lowercased.contains("enclosed") {
            return "square.dashed"
        } else if lowercased.contains("shade") || lowercased.contains("tree") {
            return "tree.fill"
        } else if lowercased.contains("bench") || lowercased.contains("seating") {
            return "chair.fill"
        } else if lowercased.contains("bag") || lowercased.contains("waste") {
            return "bag.fill"
        } else if lowercased.contains("light") {
            return "lightbulb.fill"
        } else {
            return "star.fill"
        }
    }
}

// MARK: - Park Detail ViewModel
@MainActor
class ParkDetailViewModel: ObservableObject {
    @Published var parkDetail: ParkDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentVisitors: Int?
    
    private let apiService = APIService.shared
    
    func loadParkDetails(parkId: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getParkDetails(parkId: parkId)
            parkDetail = response.park
            currentVisitors = response.park.activeVisitors
            
            print("🌐 ParkDetailViewModel: Loaded details for park \(parkId)")
        } catch {
            print("🌐 ParkDetailViewModel: Error loading park details: \(error)")
            errorMessage = "Failed to load park details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}