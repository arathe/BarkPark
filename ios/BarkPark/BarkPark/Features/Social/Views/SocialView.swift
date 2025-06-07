//
//  SocialView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct SocialView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: BarkParkDesign.Spacing.lg) {
                Spacer()
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 80))
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                
                VStack(spacing: BarkParkDesign.Spacing.sm) {
                    Text("Social")
                        .font(BarkParkDesign.Typography.title)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text("Connect with other dog owners, make friends, and arrange playdates for your dogs.")
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
            .navigationTitle("Social")
        }
    }
}

#Preview {
    SocialView()
}