//
//  MainTabView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var dogProfileViewModel = DogProfileViewModel()
    @StateObject private var dogParksViewModel = DogParksViewModel()
    @State private var selectedTab = 0 // Default to Feed tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "newspaper.fill")
                    Text("Feed")
                }
                .tag(0)
            
            DogParksView()
                .environmentObject(dogParksViewModel)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Parks")
                }
                .tag(1)
            
            SocialView()
                .environmentObject(dogParksViewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Social")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(dogProfileViewModel)
                .tag(3)
        }
        .accentColor(BarkParkDesign.Colors.dogPrimary)
        .onAppear {
            // For new users, automatically navigate to Profile tab
            if authManager.isNewUser {
                selectedTab = 3
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}