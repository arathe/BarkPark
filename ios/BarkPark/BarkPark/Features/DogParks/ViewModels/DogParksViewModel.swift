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
    @Published var searchRadius: Double = 2.0 // km
    @Published var activeCheckIns: [CheckIn] = []
    @Published var showingParkDetail = false
    
    private let apiService = APIService.shared
    private let locationManager = LocationManager.shared
    private var regionLoadTask: Task<Void, Never>?
    
    @Published var searchText: String = ""
    @Published var searchResults: [DogPark] = []
    @Published var isSearching = false
    
    // Computed property for the current active check-in
    var currentActiveCheckIn: CheckIn? {
        activeCheckIns.first { $0.isActive }
    }
    
    // Get the park for the current active check-in
    @Published var activeCheckInPark: DogPark?
    
    func loadActiveCheckInPark() async {
        guard let checkIn = currentActiveCheckIn else {
            activeCheckInPark = nil
            return
        }
        
        // First check if park is already in loaded parks
        if let park = parks.first(where: { $0.id == checkIn.dogParkId }) {
            activeCheckInPark = park
            return
        }
        
        // If not, load the park details
        if let parkDetail = await loadParkDetails(parkId: checkIn.dogParkId) {
            activeCheckInPark = DogPark(
                id: parkDetail.id,
                name: parkDetail.name,
                description: parkDetail.description,
                address: parkDetail.address,
                latitude: parkDetail.latitude,
                longitude: parkDetail.longitude,
                amenities: parkDetail.amenities,
                rules: parkDetail.rules,
                hoursOpen: parkDetail.hoursOpen,
                hoursClose: parkDetail.hoursClose,
                createdAt: "",  // Not available in ParkDetail
                updatedAt: "",  // Not available in ParkDetail
                activityLevel: parkDetail.activityLevel,
                currentVisitors: parkDetail.activeVisitors,
                distanceKm: nil
            )
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
            
            // Load park details for active check-in
            await loadActiveCheckInPark()
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
            
            // Post notification for feed refresh
            NotificationCenter.default.post(name: NSNotification.Name("RefreshFeed"), object: nil)
            
            return true
        } catch {
            print("🌐 DogParksViewModel: Error checking in: \(error)")
            // Don't set errorMessage here as it conflicts with CheckInSheetView's error handling
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
    
    func checkOutOfParkById(_ parkId: Int) async -> Bool {
        do {
            _ = try await apiService.checkOutOfPark(parkId: parkId)
            print("🌐 DogParksViewModel: Checked out of park ID \(parkId)")
            
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
    
    
    func loadParksForRegion(_ region: MKCoordinateRegion) async {
        // Cancel any pending region load task
        regionLoadTask?.cancel()
        
        // Create a new task with a small delay for debouncing
        regionLoadTask = Task {
            // Add a small delay to debounce rapid map movements
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled during the delay
            if Task.isCancelled { return }
            
            // Calculate the radius based on the visible map region
            let latitudeDelta = region.span.latitudeDelta
            let longitudeDelta = region.span.longitudeDelta
            
            // Convert the larger delta to kilometers (approximate)
            let maxDelta = max(latitudeDelta, longitudeDelta)
            let radiusInKm = maxDelta * 111.0 / 2.0 // 111km per degree latitude, divide by 2 for radius
            
            // Load parks at the center of the visible region with calculated radius
            await loadParksAtLocation(
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                customRadius: radiusInKm
            )
        }
    }
    
    func loadParksAtLocation(latitude: Double, longitude: Double, customRadius: Double? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let radius = customRadius ?? searchRadius
        
        do {
            print("🌐 DogParksViewModel: Loading parks near \(latitude), \(longitude) within \(radius)km")
            let response = try await apiService.getNearbyParks(
                latitude: latitude,
                longitude: longitude,
                radius: radius
            )
            
            parks = response.parks
            print("🌐 DogParksViewModel: Loaded \(parks.count) parks")
            
        } catch {
            // Don't show error for cancelled tasks
            if error is CancellationError {
                print("🌐 DogParksViewModel: Park loading was cancelled")
            } else {
                print("🌐 DogParksViewModel: Error loading parks: \(error)")
                if parks.isEmpty {
                    errorMessage = "Failed to load nearby parks: \(error.localizedDescription)"
                }
            }
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
    
    func searchParks(_ searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        do {
            let response = try await apiService.searchParks(
                query: searchText,
                latitude: locationManager.location?.coordinate.latitude,
                longitude: locationManager.location?.coordinate.longitude
            )
            
            searchResults = response.parks
            print("🔍 DogParksViewModel: Found \(searchResults.count) parks for '\(searchText)'")
        } catch {
            print("🔍 DogParksViewModel: Error searching parks: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("🔍 DogParksViewModel: Missing key '\(key.stringValue)' - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("🔍 DogParksViewModel: Type mismatch for type '\(type)' - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("🔍 DogParksViewModel: Value not found for type '\(type)' - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("🔍 DogParksViewModel: Data corrupted - \(context.debugDescription)")
                @unknown default:
                    print("🔍 DogParksViewModel: Unknown decoding error")
                }
            }
            errorMessage = "Failed to search parks: \(error.localizedDescription)"
            searchResults = []
        }
        
        isSearching = false
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
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
