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
                
                TextField("Search owners, dogs, or emails", text: $viewModel.searchQuery)
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
                
                Text("Search for owners, their dogs, or email addresses to find new friends at the park.")
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
            
            Text("Enter at least 2 characters to search owners, dogs, or emails")
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
                
                Text("No owners, dogs, or emails match your search for \"\(viewModel.searchQuery)\". Try a different search term.")
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

    private var resolvedDogs: [UserDogSummary] {
        user.dogs ?? viewModel.dogSummariesByUserId[user.id] ?? []
    }
    private var hasDogs: Bool { !resolvedDogs.isEmpty }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: BarkParkDesign.Spacing.md) {
                // Owner profile (tappable)
                NavigationLink(destination: UserProfileView(userId: user.id)) {
                    HStack(spacing: BarkParkDesign.Spacing.md) {
                        profileImageView
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(BarkParkDesign.Typography.headline)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)

                            Text(user.email)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                actionButton
            }

            if hasDogs {
                // Simple text line for visibility and debugging
                let names = resolvedDogs.map { $0.name }.joined(separator: ", ")
                Text("Dogs: \(names)")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                dogChips
            }

            Text(friendshipStatus)
                .font(BarkParkDesign.Typography.caption)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, BarkParkDesign.Spacing.xs)
        .onAppear {
            updateFriendshipStatus()
            // Fetch dog summaries if server didn't include them
            if user.dogs?.isEmpty ?? true {
                Task { await viewModel.fetchDogSummariesIfNeeded(for: user.id) }
            }
        }
    }

    // MARK: - Dog Chips
    private var dogChips: some View {
        let dogs = resolvedDogs
        // Highlight chips that match current search query
        let query = viewModel.searchQuery.lowercased()
        let highlighted = dogs.filter { $0.name.lowercased().contains(query) }
        let nonHighlighted = dogs.filter { !$0.name.lowercased().contains(query) }

        // Limit visible chips to avoid overflow
        let maxChips = 4
        let ordered = highlighted + nonHighlighted
        let visible = Array(ordered.prefix(maxChips))
        let remaining = max(dogs.count - visible.count, 0)

        return HStack(spacing: 6) {
            ForEach(visible) { dog in
                let isMatch = dog.name.lowercased().contains(query) && !query.isEmpty
                Text(dog.name)
                    .font(BarkParkDesign.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(isMatch ? BarkParkDesign.Colors.dogPrimary.opacity(0.15) : BarkParkDesign.Colors.tertiaryBackground)
                    )
                    .overlay(
                        Capsule()
                            .stroke(isMatch ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(isMatch ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.secondaryText)
            }

            if remaining > 0 {
                Text("+\(remaining)")
                    .font(BarkParkDesign.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(BarkParkDesign.Colors.tertiaryBackground)
                    )
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
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

    // MARK: - Profile Image
    private var profileImageView: some View {
        Group {
            if let urlString = user.profileImageUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 1)
                )
            } else {
                Circle()
                    .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.firstName.prefix(1))
                            .font(BarkParkDesign.Typography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    )
                    .overlay(
                        Circle().stroke(BarkParkDesign.Colors.dogPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
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
