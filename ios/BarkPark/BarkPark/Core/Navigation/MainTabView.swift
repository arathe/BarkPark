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
    @State private var selectedTab = 0 // Default to Parks tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DogParksView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Parks")
                }
                .tag(0)
            
            SocialView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Social")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .environmentObject(dogProfileViewModel)
                .tag(2)
        }
        .accentColor(BarkParkDesign.Colors.dogPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}