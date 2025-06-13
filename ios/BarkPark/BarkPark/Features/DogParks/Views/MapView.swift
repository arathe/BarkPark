//
//  MapView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/11/25.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let parks: [DogPark]
    let initialRegion: MKCoordinateRegion
    @Binding var selectedPark: DogPark?
    let onParkSelected: (DogPark) -> Void
    let onRegionChanged: ((MKCoordinateRegion) -> Void)?
    @Binding var centerOnLocation: CLLocationCoordinate2D?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = initialRegion
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Enable clustering for performance
        mapView.register(ParkAnnotationView.self, forAnnotationViewWithReuseIdentifier: ParkAnnotationView.identifier)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Only update region when explicitly requested via centerOnLocation
        if let centerLocation = centerOnLocation {
            let newRegion = MKCoordinateRegion(
                center: centerLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            mapView.setRegion(newRegion, animated: true)
            
            // Clear the centerOnLocation after using it
            DispatchQueue.main.async {
                self.centerOnLocation = nil
            }
        }
        
        // Update annotations
        let currentAnnotations = mapView.annotations.compactMap { $0 as? ParkAnnotation }
        let newAnnotations = parks.map { park in
            ParkAnnotation(park: park, isCheckedIn: false) // TODO: Pass check-in status
        }
        
        // Only update annotations if they actually changed
        let currentParkIds = Set(currentAnnotations.map { $0.park.id })
        let newParkIds = Set(parks.map { $0.id })
        
        if currentParkIds != newParkIds {
            // Remove old annotations
            mapView.removeAnnotations(currentAnnotations)
            
            // Add new annotations
            mapView.addAnnotations(newAnnotations)
        }
        
        // Update coordinator with latest parks data
        context.coordinator.parks = parks
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var parks: [DogPark] = []
        var isUserInteracting = false
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let parkAnnotation = annotation as? ParkAnnotation else {
                return nil
            }
            
            let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: ParkAnnotationView.identifier,
                for: annotation
            ) as? ParkAnnotationView ?? ParkAnnotationView(annotation: annotation, reuseIdentifier: ParkAnnotationView.identifier)
            
            annotationView.configure(with: parkAnnotation.park)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let parkAnnotation = view.annotation as? ParkAnnotation else { return }
            
            parent.selectedPark = parkAnnotation.park
            parent.onParkSelected(parkAnnotation.park)
            
            // Deselect the annotation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                mapView.deselectAnnotation(parkAnnotation, animated: true)
            }
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // Detect if the change is due to user interaction
            if let gestureRecognizers = mapView.subviews.first?.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    if recognizer.state == .began || recognizer.state == .changed {
                        isUserInteracting = true
                        break
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // DON'T update the parent region binding to prevent snap-back
            // Only notify about region changes for loading parks
            DispatchQueue.main.async {
                self.parent.onRegionChanged?(mapView.region)
            }
            
            // Reset interaction flag
            isUserInteracting = false
        }
    }
}

// MARK: - Custom Annotation View
class ParkAnnotationView: MKMarkerAnnotationView {
    static let identifier = "ParkAnnotationView"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        canShowCallout = true
        animatesWhenAdded = true
        isDraggable = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with park: DogPark) {
        // Set marker color based on activity level
        guard let level = park.activityLevel else {
            markerTintColor = .systemGray
            return
        }
        
        switch level.lowercased() {
        case "quiet":
            markerTintColor = .systemGreen
        case "low":
            markerTintColor = .systemBlue
        case "moderate":
            markerTintColor = .systemOrange
        case "busy":
            markerTintColor = .systemRed
        default:
            markerTintColor = .systemGray
        }
        
        // Set the glyph
        glyphImage = UIImage(systemName: "pawprint.fill")
        
        // Configure callout
        let calloutButton = UIButton(type: .detailDisclosure)
        rightCalloutAccessoryView = calloutButton
        
        // Add activity level indicator
        let activityLabel = UILabel()
        activityLabel.text = park.activityLevelText
        activityLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        activityLabel.textColor = .white
        activityLabel.backgroundColor = markerTintColor
        activityLabel.textAlignment = .center
        activityLabel.layer.cornerRadius = 8
        activityLabel.layer.masksToBounds = true
        activityLabel.frame = CGRect(x: 0, y: 0, width: 60, height: 16)
        
        leftCalloutAccessoryView = activityLabel
    }
}

// MARK: - Helper Extensions
extension CLLocationCoordinate2D {
    func isEqual(to other: CLLocationCoordinate2D, precision: Double = 0.0001) -> Bool {
        return abs(latitude - other.latitude) < precision &&
               abs(longitude - other.longitude) < precision
    }
}

extension MKCoordinateSpan {
    func isEqual(to other: MKCoordinateSpan, precision: Double = 0.0001) -> Bool {
        return abs(latitudeDelta - other.latitudeDelta) < precision &&
               abs(longitudeDelta - other.longitudeDelta) < precision
    }
}