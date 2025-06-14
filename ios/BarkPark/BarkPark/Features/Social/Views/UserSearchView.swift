//
//  UserSearchView.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import SwiftUI

struct UserSearchView: View {
    @ObservedObject var viewModel: SocialViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Search Results
                searchResults
            }
            .navigationTitle("Find Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        VStack(spacing: BarkParkDesign.Spacing.sm) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                
                TextField("Search by name or email", text: $viewModel.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
            }
            .padding(BarkParkDesign.Spacing.md)
            .background(BarkParkDesign.Colors.surface)
            .cornerRadius(10)
            .padding(.horizontal, BarkParkDesign.Spacing.md)
            
            if viewModel.isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching...")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                .padding(.horizontal, BarkParkDesign.Spacing.md)
            }
        }
        .padding(.vertical, BarkParkDesign.Spacing.md)
        .background(BarkParkDesign.Colors.background)
    }
    
    private var searchResults: some View {
        Group {
            if viewModel.searchQuery.isEmpty {
                searchPromptView
            } else if viewModel.searchQuery.count < 2 {
                searchTooShortView
            } else if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                noResultsView
            } else {
                resultsList
            }
        }
    }
    
    private var searchPromptView: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text("Search for Friends")
                    .font(BarkParkDesign.Typography.title2)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("Enter a name or email address to find other dog owners to connect with.")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchTooShortView: some View {
        VStack(spacing: BarkParkDesign.Spacing.md) {
            Image(systemName: "text.cursor")
                .font(.system(size: 40))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            Text("Keep typing...")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Text("Enter at least 2 characters to search")
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text("No Users Found")
                    .font(BarkParkDesign.Typography.title2)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("No users match your search for \"\(viewModel.searchQuery)\". Try a different search term.")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsList: some View {
        List(viewModel.searchResults) { user in
            UserSearchRowView(user: user, viewModel: viewModel)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - User Search Row View
struct UserSearchRowView: View {
    let user: User
    let viewModel: SocialViewModel
    @State private var friendshipStatus: String = "Loading..."
    @State private var canSendRequest = false
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            // Profile Image Placeholder
            Circle()
                .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.firstName.prefix(1))
                        .font(BarkParkDesign.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text(user.email)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                
                Text(friendshipStatus)
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            actionButton
        }
        .padding(.vertical, BarkParkDesign.Spacing.xs)
        .onAppear {
            updateFriendshipStatus()
        }
    }
    
    private var actionButton: some View {
        Group {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if canSendRequest {
                Button("Add Friend") {
                    sendFriendRequest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(BarkParkDesign.Colors.dogPrimary)
            } else {
                // Show status-specific button or no button
                EmptyView()
            }
        }
    }
    
    private var statusColor: Color {
        switch friendshipStatus {
        case "Already friends":
            return .green
        case "Request sent":
            return BarkParkDesign.Colors.dogPrimary
        case "Request received":
            return .blue
        default:
            return BarkParkDesign.Colors.secondaryText
        }
    }
    
    private func updateFriendshipStatus() {
        // Check if already a friend
        if viewModel.isAlreadyFriend(user) {
            friendshipStatus = "Already friends"
            canSendRequest = false
            return
        }
        
        // Check if there's a pending request
        if let request = viewModel.hasPendingRequest(with: user) {
            switch request.requestType {
            case .sent:
                friendshipStatus = "Request sent"
                canSendRequest = false
            case .received:
                friendshipStatus = "Request received"
                canSendRequest = false
            }
            return
        }
        
        // Can send request
        friendshipStatus = "Available to add"
        canSendRequest = true
    }
    
    private func sendFriendRequest() {
        isLoading = true
        Task {
            await viewModel.sendFriendRequest(to: user)
            await MainActor.run {
                updateFriendshipStatus()
                isLoading = false
            }
        }
    }
}

#Preview {
    UserSearchView(viewModel: SocialViewModel())
}