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
        Group {
            if authManager.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .environmentObject(authManager)
    }
}

#Preview {
    RootView()
}