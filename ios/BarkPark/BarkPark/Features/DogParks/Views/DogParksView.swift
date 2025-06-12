//
//  DogParksView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI
import MapKit

struct DogParksView: View {
    @StateObject private var viewModel = DogParksViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingLocationPrompt = false
    @State private var showingRadiusSheet = false
    @State private var lastRegionChangeTime = Date()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0387, longitude: -73.9215),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var mapViewID = UUID() // Use this to force recreate the map when needed
    @State private var centerOnLocation: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(
                    parks: viewModel.parks,
                    initialRegion: mapRegion,
                    selectedPark: $viewModel.selectedPark,
                    onParkSelected: { park in
                        viewModel.selectPark(park)
                    },
                    onRegionChanged: { newRegion in
                        Task {
                            await viewModel.loadParksForRegion(newRegion)
                        }
                    },
                    centerOnLocation: $centerOnLocation
                )
                .onAppear {
                    requestLocationIfNeeded()
                    // Initialize map region from location manager only once
                    if let userLocation = locationManager.location {
                        mapRegion = MKCoordinateRegion(
                            center: userLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                        )
                    }
                    // Parks will load automatically when the map region changes
                }
                
                // Top controls overlay
                VStack {
                    HStack {
                        // Radius control
                        Button(action: {
                            showingRadiusSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle")
                                Text(viewModel.radiusText)
                            }
                            .font(BarkParkDesign.Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        
                        Spacer()
                        
                        // Refresh button
                        Button(action: {
                            Task {
                                await viewModel.loadParksForRegion(mapRegion)
                                await viewModel.loadActiveCheckIns()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color.white)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .disabled(viewModel.isLoading)
                        
                        // Location button
                        Button(action: {
                            if locationManager.hasLocationPermission {
                                locationManager.getCurrentLocation()
                                // Update map to user's location
                                if let userLocation = locationManager.location {
                                    centerOnLocation = userLocation.coordinate
                                }
                            } else {
                                showingLocationPrompt = true
                            }
                        }) {
                            Image(systemName: locationManager.hasLocationPermission ? "location" : "location.slash")
                                .font(.system(size: 16, weight: .medium))
                                .padding(10)
                                .background(Color.white)
                                .foregroundColor(locationManager.hasLocationPermission ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.secondaryText)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, BarkParkDesign.Spacing.md)
                    
                    Spacer()
                    
                    // Loading indicator
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading parks...")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .navigationTitle("Dog Parks")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Location Access", isPresented: $showingLocationPrompt) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enable location access to find nearby dog parks. You can change this in Settings.")
            }
            .actionSheet(isPresented: $showingRadiusSheet) {
                ActionSheet(
                    title: Text("Search Radius"),
                    message: Text("How far should we search for dog parks?"),
                    buttons: viewModel.radiusOptions.map { radius in
                        .default(Text(radius < 1 ? "\(Int(radius * 1000))m" : "\(Int(radius))km")) {
                            viewModel.updateSearchRadius(radius)
                        }
                    } + [.cancel()]
                )
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $viewModel.showingParkDetail) {
            if let selectedPark = viewModel.selectedPark {
                ParkDetailView(
                    park: selectedPark,
                    isCheckedIn: viewModel.isCheckedIn(to: selectedPark),
                    onCheckIn: { dogsPresent in
                        await viewModel.checkInToPark(selectedPark, dogsPresent: dogsPresent)
                    },
                    onCheckOut: {
                        await viewModel.checkOutOfPark(selectedPark)
                    }
                )
            }
        }
    }
    
    private func requestLocationIfNeeded() {
        if locationManager.canRequestLocation {
            locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    DogParksView()
}