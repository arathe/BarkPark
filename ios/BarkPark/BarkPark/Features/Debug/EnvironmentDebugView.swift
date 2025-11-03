//
//  EnvironmentDebugView.swift
//  BarkPark
//
//  Created by Austin Rathe on 11/3/25.
//

import SwiftUI

struct EnvironmentDebugView: View {
    @Environment(\.dismiss) private var dismiss
    private let environment = APIConfiguration.currentEnvironment
    private let baseURL = APIConfiguration.baseURL
    
    private var environmentOverrides: [(label: String, value: String?)] {
        [
            ("BARKPARK_ENVIRONMENT", ProcessInfo.processInfo.environment["BARKPARK_ENVIRONMENT"]),
            ("LOCAL_API_URL", ProcessInfo.processInfo.environment["LOCAL_API_URL"]),
            ("DATABASE_URL", ProcessInfo.processInfo.environment["DATABASE_URL"])
        ]
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("Current Configuration") {
                    LabeledContent("Environment") {
                        Text(environmentLabel)
                            .fontWeight(.semibold)
                    }
                    
                    LabeledContent("Base URL") {
                        Text(baseURL)
                            .textSelection(.enabled)
                    }
                }
                
                Section("Overrides") {
                    ForEach(environmentOverrides, id: \.label) { item in
                        LabeledContent(item.label) {
                            if let value = item.value, !value.isEmpty {
                                Text(value)
                                    .textSelection(.enabled)
                            } else {
                                Text("Not set")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    Text("Update environment via `BARKPARK_ENVIRONMENT` (local, staging, production).")
                    Text("Override local development base URL with `LOCAL_API_URL` when testing against another machine.")
                }
            }
            .navigationTitle("Environment Debug")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var environmentLabel: String {
        switch environment {
        case .local:
            return "Local"
        case .staging:
            return "Staging"
        case .production:
            return "Production"
        }
    }
}

#Preview {
    EnvironmentDebugView()
}
