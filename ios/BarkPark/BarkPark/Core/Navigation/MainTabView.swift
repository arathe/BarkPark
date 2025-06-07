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
    
    var body: some View {
        TabView {
            MyPackView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("My Pack")
                }
                .environmentObject(dogProfileViewModel)
            
            DogParksView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Parks")
                }
            
            SocialView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Social")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(BarkParkDesign.Colors.dogPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}