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
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPark: DogPark?
    let onParkSelected: (DogPark) -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Enable clustering for performance
        mapView.register(ParkAnnotationView.self, forAnnotationViewWithReuseIdentifier: ParkAnnotationView.identifier)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if it changed
        if !mapView.region.center.isEqual(to: region.center) ||
           !mapView.region.span.isEqual(to: region.span) {
            mapView.setRegion(region, animated: true)
        }
        
        // Update annotations
        let currentAnnotations = mapView.annotations.compactMap { $0 as? ParkAnnotation }
        let newAnnotations = parks.map { park in
            ParkAnnotation(park: park, isCheckedIn: false) // TODO: Pass check-in status
        }
        
        // Remove old annotations
        mapView.removeAnnotations(currentAnnotations)
        
        // Add new annotations
        mapView.addAnnotations(newAnnotations)
        
        // Update coordinator with latest parks data
        context.coordinator.parks = parks
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var parks: [DogPark] = []
        
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
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
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
        switch park.activityColor {
        case "green":
            markerTintColor = .systemGreen
        case "blue":
            markerTintColor = .systemBlue
        case "orange":
            markerTintColor = .systemOrange
        case "red":
            markerTintColor = .systemRed
        case "purple":
            markerTintColor = .systemPurple
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