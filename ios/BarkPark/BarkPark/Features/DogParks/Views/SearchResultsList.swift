//
//  SearchResultsList.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/12/25.
//

import SwiftUI
import CoreLocation

struct SearchResultsList: View {
    let searchResults: [DogPark]
    let userLocation: CLLocationCoordinate2D?
    let onParkSelected: (DogPark) -> Void
    
    // Sort parks by distance from user location
    private var sortedResults: [DogPark] {
        guard let userLocation = userLocation else {
            return searchResults
        }
        
        return searchResults.sorted { park1, park2 in
            let distance1 = park1.coordinate.distance(from: userLocation)
            let distance2 = park2.coordinate.distance(from: userLocation)
            return distance1 < distance2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !searchResults.isEmpty {
                // Header
                HStack {
                    Text("\(searchResults.count) result\(searchResults.count == 1 ? "" : "s")")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Results list in ScrollView
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sortedResults, id: \.id) { park in
                            SearchResultRow(
                                park: park,
                                userLocation: userLocation,
                                onTap: { onParkSelected(park) }
                            )
                            
                            if park.id != sortedResults.last?.id {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300) // Limit height to maintain overlay appearance
                .padding(.bottom, 8)
            }
        }
    }
}

struct SearchResultRow: View {
    let park: DogPark
    let userLocation: CLLocationCoordinate2D?
    let onTap: () -> Void
    
    private var distanceText: String {
        guard let userLocation = userLocation else {
            return ""
        }
        
        let distance = park.coordinate.distance(from: userLocation)
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Park activity indicator
                Circle()
                    .fill(park.activityColorSwiftUI)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(park.name)
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if !distanceText.isEmpty {
                            Text(distanceText)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                        
                        Text(park.activityLevelText)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        if let visitors = park.currentVisitors, visitors > 0 {
                            Text("• \(visitors) visitor\(visitors == 1 ? "" : "s")")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BarkParkDesign.Colors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.clear)
    }
}

// MARK: - CLLocationCoordinate2D Distance Extension
extension CLLocationCoordinate2D {
    func distance(from coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2)
    }
}

#Preview {
    SearchResultsList(
        searchResults: [
            DogPark(
                id: 1,
                name: "Central Park Dog Run",
                description: "Large off-leash area",
                address: "Central Park, New York, NY",
                latitude: 40.7829,
                longitude: -73.9654,
                amenities: [],
                rules: nil,
                hoursOpen: nil,
                hoursClose: nil,
                createdAt: "2024-01-01T00:00:00Z",
                updatedAt: "2024-01-01T00:00:00Z",
                activityLevel: "moderate",
                currentVisitors: 5,
                distanceKm: nil
            ),
            DogPark(
                id: 2,
                name: "Prospect Park Dog Beach",
                description: "Waterfront dog area",
                address: "Prospect Park, Brooklyn, NY",
                latitude: 40.6602,
                longitude: -73.9690,
                amenities: [],
                rules: nil,
                hoursOpen: nil,
                hoursClose: nil,
                createdAt: "2024-01-01T00:00:00Z",
                updatedAt: "2024-01-01T00:00:00Z",
                activityLevel: "low",
                currentVisitors: 2,
                distanceKm: nil
            )
        ],
        userLocation: CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
        onParkSelected: { _ in }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}