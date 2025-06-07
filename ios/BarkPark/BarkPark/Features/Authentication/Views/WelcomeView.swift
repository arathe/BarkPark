//
//  WelcomeView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [BarkParkDesign.Colors.dogPrimary.opacity(0.1), BarkParkDesign.Colors.dogSecondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: BarkParkDesign.Spacing.xl) {
                    Spacer()
                    
                    // App Icon and Title
                    VStack(spacing: BarkParkDesign.Spacing.lg) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 80))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        
                        Text("BarkPark")
                            .font(BarkParkDesign.Typography.largeTitle)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Text("Connect with fellow dog lovers")
                            .font(BarkParkDesign.Typography.title3)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: BarkParkDesign.Spacing.md) {
                        Button("Get Started") {
                            showSignUp = true
                        }
                        .barkParkButton()
                        
                        Button("Already have an account?") {
                            showLogin = true
                        }
                        .barkParkSecondaryButton()
                    }
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationManager())
}