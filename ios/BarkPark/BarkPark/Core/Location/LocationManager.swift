//
//  LocationManager.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isUpdatingLocation = false
    @Published var locationError: LocationError?
    
    // Default region around Piermont, NY (where test parks are seeded)
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0387, longitude: -73.9215),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
        
        // Set initial region to user location if available
        if let userLocation = locationManager.location {
            location = userLocation
            region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
    
    func requestLocationPermission() {
        print("🗺️ LocationManager: Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("🗺️ LocationManager: Location not authorized")
            locationError = .notAuthorized
            return
        }
        
        print("🗺️ LocationManager: Starting location updates")
        isUpdatingLocation = true
        locationError = nil
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("🗺️ LocationManager: Stopping location updates")
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        if let currentLocation = locationManager.location {
            location = currentLocation
            updateRegion(to: currentLocation.coordinate)
        } else {
            startUpdatingLocation()
        }
    }
    
    func updateRegion(to coordinate: CLLocationCoordinate2D, span: MKCoordinateSpan? = nil) {
        let newSpan = span ?? MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        region = MKCoordinateRegion(center: coordinate, span: newSpan)
    }
    
    var hasLocationPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var canRequestLocation: Bool {
        return authorizationStatus == .notDetermined
    }
    
    var permissionDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }
    
    // Calculate distance between two coordinates
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // Convert to kilometers
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        
        print("🗺️ LocationManager: Location updated to \(latestLocation.coordinate)")
        
        DispatchQueue.main.async {
            self.location = latestLocation
            self.updateRegion(to: latestLocation.coordinate)
            self.locationError = nil
            
            // Stop updating after getting a location to save battery
            self.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("🗺️ LocationManager: Location error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.isUpdatingLocation = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = .notAuthorized
                case .network:
                    self.locationError = .networkError
                case .locationUnknown:
                    self.locationError = .locationUnavailable
                default:
                    self.locationError = .unknown(clError.localizedDescription)
                }
            } else {
                self.locationError = .unknown(error.localizedDescription)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🗺️ LocationManager: Authorization status changed to \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                if self.location == nil {
                    self.getCurrentLocation()
                }
            case .denied, .restricted:
                self.locationError = .notAuthorized
                self.stopUpdatingLocation()
            case .notDetermined:
                self.locationError = nil
            @unknown default:
                self.locationError = .unknown("Unknown authorization status")
            }
        }
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case notAuthorized
    case networkError
    case locationUnavailable
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Location access not authorized. Please enable location services in Settings."
        case .networkError:
            return "Network error occurred while getting location."
        case .locationUnavailable:
            return "Unable to determine your location at this time."
        case .unknown(let message):
            return "Location error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Go to Settings > Privacy & Security > Location Services and enable location access for BarkPark."
        case .networkError:
            return "Please check your internet connection and try again."
        case .locationUnavailable:
            return "Try moving to an area with better GPS signal."
        case .unknown:
            return "Please try again or restart the app."
        }
    }
}