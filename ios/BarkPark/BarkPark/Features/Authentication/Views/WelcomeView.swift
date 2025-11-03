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
    @State private var showEnvironmentDetails = false
    
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
                    
                    Button {
                        showEnvironmentDetails = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                            Text("Environment Details")
                        }
                        .font(.footnote)
                    }
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .padding(.top, BarkParkDesign.Spacing.sm)
                    
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
        .sheet(isPresented: $showEnvironmentDetails) {
            EnvironmentDebugView()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationManager())
}
