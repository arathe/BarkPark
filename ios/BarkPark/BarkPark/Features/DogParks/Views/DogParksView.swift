//
//  DogParksView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI
import MapKit

struct DogParksView: View {
    @EnvironmentObject var viewModel: DogParksViewModel
    @StateObject private var locationManager = LocationManager.shared
    @State private var showingLocationPrompt = false
    @State private var showingSearchResults = false
    @State private var lastRegionChangeTime = Date()
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0387, longitude: -73.9215),
        span: MKCoordinateSpan(latitudeDelta: 0.036, longitudeDelta: 0.036)
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
                            span: MKCoordinateSpan(latitudeDelta: 0.036, longitudeDelta: 0.036)
                        )
                    }
                    // Parks will load automatically when the map region changes
                }
                
                // Top search and controls overlay
                VStack {
                    HStack {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                .font(.system(size: 16))
                            
                            TextField("Search dog parks...", text: $viewModel.searchText)
                                .font(BarkParkDesign.Typography.body)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                                .onSubmit {
                                    Task {
                                        await viewModel.searchParks(viewModel.searchText)
                                        showingSearchResults = !viewModel.searchResults.isEmpty
                                    }
                                }
                                .onChange(of: viewModel.searchText) { newValue in
                                    if newValue.isEmpty {
                                        viewModel.clearSearch()
                                        showingSearchResults = false
                                    } else {
                                        Task {
                                            await viewModel.searchParks(newValue)
                                            showingSearchResults = !viewModel.searchResults.isEmpty
                                        }
                                    }
                                }
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.clearSearch()
                                    showingSearchResults = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
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
                    
                    // Search results dropdown
                    if showingSearchResults && !viewModel.searchResults.isEmpty {
                        SearchResultsList(
                            searchResults: viewModel.searchResults,
                            userLocation: locationManager.location?.coordinate,
                            onParkSelected: { park in
                                viewModel.selectPark(park)
                                showingSearchResults = false
                                viewModel.clearSearch()
                                
                                // Center map on selected park
                                centerOnLocation = park.coordinate
                            }
                        )
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, BarkParkDesign.Spacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Spacer()
                    
                    // Active check-in card
                    if let activeCheckIn = viewModel.currentActiveCheckIn {
                        ActiveCheckInCard(
                            checkIn: activeCheckIn,
                            parkName: viewModel.activeCheckInPark?.name ?? "Loading...",
                            onCheckOut: {
                                Task {
                                    await viewModel.checkOutOfParkById(activeCheckIn.dogParkId)
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(), value: activeCheckIn)
                        .padding(.bottom, 8)
                    }
                    
                    // Loading indicator
                    if viewModel.isLoading || viewModel.isSearching {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(viewModel.isSearching ? "Searching..." : "Loading parks...")
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
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK") { }
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