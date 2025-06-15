//
//  RootView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingNewUserDogCreation = false
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .sheet(isPresented: $showingNewUserDogCreation) {
                        NavigationView {
                            MyDogsView()
                                .environmentObject(DogProfileViewModel())
                                .environmentObject(authManager)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button("Skip") {
                                            authManager.clearNewUserFlag()
                                            showingNewUserDogCreation = false
                                        }
                                    }
                                }
                        }
                        .interactiveDismissDisabled()
                    }
                    .onChange(of: authManager.isNewUser) { newValue in
                        if newValue {
                            showingNewUserDogCreation = true
                        }
                    }
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