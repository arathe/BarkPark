//
//  DogParksViewModel.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class DogParksViewModel: ObservableObject {
    @Published var parks: [DogPark] = []
    @Published var selectedPark: DogPark?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchRadius: Double = 10.0 // km
    @Published var activeCheckIns: [CheckIn] = []
    @Published var showingParkDetail = false
    
    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared
    
    // Search radius options
    let radiusOptions: [Double] = [1.0, 5.0, 10.0, 25.0]
    
    var radiusText: String {
        if searchRadius < 1 {
            return "\(Int(searchRadius * 1000))m"
        } else {
            return "\(Int(searchRadius))km"
        }
    }
    
    init() {
        // Load initial data
        Task {
            await loadActiveCheckIns()
        }
    }
    
    func loadNearbyParks() async {
        guard let userLocation = locationManager.location else {
            // Use default location (Piermont, NY) if user location not available
            await loadParksAtLocation(
                latitude: 41.0387,
                longitude: -73.9215
            )
            return
        }
        
        await loadParksAtLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )
    }
    
    func loadParksAtLocation(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🌐 DogParksViewModel: Loading parks near \(latitude), \(longitude) within \(searchRadius)km")
            let response = try await apiService.getNearbyParks(
                latitude: latitude,
                longitude: longitude,
                radius: searchRadius
            )
            
            parks = response.parks
            print("🌐 DogParksViewModel: Loaded \(parks.count) parks")
            
        } catch {
            print("🌐 DogParksViewModel: Error loading parks: \(error)")
            errorMessage = "Failed to load nearby parks: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadParkDetails(parkId: Int) async -> ParkDetail? {
        do {
            let response = try await apiService.getParkDetails(parkId: parkId)
            return response.park
        } catch {
            print("🌐 DogParksViewModel: Error loading park details: \(error)")
            errorMessage = "Failed to load park details: \(error.localizedDescription)"
            return nil
        }
    }
    
    func loadActiveCheckIns() async {
        do {
            let response = try await apiService.getActiveCheckIns()
            activeCheckIns = response.activeCheckIns
            print("🌐 DogParksViewModel: Loaded \(activeCheckIns.count) active check-ins")
        } catch {
            print("🌐 DogParksViewModel: Error loading active check-ins: \(error)")
        }
    }
    
    func checkInToPark(_ park: DogPark, dogsPresent: [Int] = []) async -> Bool {
        do {
            _ = try await apiService.checkInToPark(parkId: park.id, dogsPresent: dogsPresent)
            print("🌐 DogParksViewModel: Checked in to \(park.name)")
            
            // Reload active check-ins
            await loadActiveCheckIns()
            
            return true
        } catch {
            print("🌐 DogParksViewModel: Error checking in: \(error)")
            errorMessage = "Failed to check in: \(error.localizedDescription)"
            return false
        }
    }
    
    func checkOutOfPark(_ park: DogPark) async -> Bool {
        do {
            _ = try await apiService.checkOutOfPark(parkId: park.id)
            print("🌐 DogParksViewModel: Checked out of \(park.name)")
            
            // Reload active check-ins
            await loadActiveCheckIns()
            
            return true
        } catch {
            print("🌐 DogParksViewModel: Error checking out: \(error)")
            errorMessage = "Failed to check out: \(error.localizedDescription)"
            return false
        }
    }
    
    func refreshParks() async {
        await loadNearbyParks()
        await loadActiveCheckIns()
    }
    
    func updateSearchRadius(_ newRadius: Double) {
        searchRadius = newRadius
        Task {
            await loadNearbyParks()
        }
    }
    
    func selectPark(_ park: DogPark) {
        selectedPark = park
        showingParkDetail = true
    }
    
    func isCheckedIn(to park: DogPark) -> Bool {
        return activeCheckIns.contains { $0.dogParkId == park.id && $0.isActive }
    }
    
    func getActiveCheckIn(for park: DogPark) -> CheckIn? {
        return activeCheckIns.first { $0.dogParkId == park.id && $0.isActive }
    }
    
    // Get annotation color based on activity level
    func annotationColor(for park: DogPark) -> String {
        if isCheckedIn(to: park) {
            return "purple" // Special color for checked-in parks
        }
        return park.activityColor
    }
    
    // Get activity level text with check-in status
    func activityText(for park: DogPark) -> String {
        if isCheckedIn(to: park) {
            return "Checked In"
        }
        return park.activityLevelText
    }
}

// MARK: - Park Annotation
class ParkAnnotation: NSObject, MKAnnotation, Identifiable {
    let id: Int
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let park: DogPark
    
    init(park: DogPark, isCheckedIn: Bool = false) {
        self.id = park.id
        self.coordinate = park.coordinate
        self.title = park.name
        self.park = park
        
        if isCheckedIn {
            self.subtitle = "Checked In • \(park.activityLevelText)"
        } else {
            let visitorText = park.currentVisitors != nil ? " • \(park.currentVisitors!) visitors" : ""
            self.subtitle = "\(park.activityLevelText)\(visitorText)"
        }
        
        super.init()
    }
}