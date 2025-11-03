//
//  RootView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(authManager)
            
            EnvironmentBannerView()
                .padding(.top, 12)
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    RootView()
}

// MARK: - Environment Banner
private struct EnvironmentBannerView: View {
    private let environment = APIConfiguration.currentEnvironment
    private let baseURL = APIConfiguration.baseURL
    
    var body: some View {
        Group {
            if environment != .production {
                HStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(environmentLabel)
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Text(baseURL)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.65))
                )
                .foregroundColor(.white)
                .shadow(radius: 3)
            }
        }
    }
    
    private var environmentLabel: String {
        switch environment {
        case .local:
            return "Local API"
        case .staging:
            return "Staging API"
        case .production:
            return "Production API"
        }
    }
}
