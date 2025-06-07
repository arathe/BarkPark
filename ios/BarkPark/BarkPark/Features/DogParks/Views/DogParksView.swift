//
//  DogParksView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct DogParksView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: BarkParkDesign.Spacing.lg) {
                Spacer()
                
                Image(systemName: "map.fill")
                    .font(.system(size: 80))
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                
                VStack(spacing: BarkParkDesign.Spacing.sm) {
                    Text("Dog Parks")
                        .font(BarkParkDesign.Typography.title)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text("Find nearby dog parks and connect with other dog owners in your area.")
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BarkParkDesign.Spacing.lg)
                    
                    Text("Coming Soon!")
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        .padding(.top, BarkParkDesign.Spacing.md)
                }
                
                Spacer()
            }
            .navigationTitle("Parks")
        }
    }
}

#Preview {
    DogParksView()
}