//
//  BarkParkApp.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

@main
struct BarkParkApp: App {
    init() {
        // Log environment configuration on app startup
        #if DEBUG
        APIConfiguration.logEnvironment()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}