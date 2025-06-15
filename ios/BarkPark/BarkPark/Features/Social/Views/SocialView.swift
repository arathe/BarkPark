//
//  SocialView.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import SwiftUI

struct SocialView: View {
    @StateObject private var viewModel = SocialViewModel()
    @StateObject private var parksViewModel = DogParksViewModel()
    @State private var selectedTab = 0
    @State private var showingUserSearch = false
    @State private var showingQRDisplay = false
    @State private var showingQRScanner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Picker
                customTabPicker
                
                // Active check-in card
                if let activeCheckIn = parksViewModel.currentActiveCheckIn {
                    ActiveCheckInCard(
                        checkIn: activeCheckIn,
                        parkName: parksViewModel.activeCheckInPark?.name ?? "Loading...",
                        onCheckOut: {
                            Task {
                                await parksViewModel.checkOutOfParkById(activeCheckIn.dogParkId)
                            }
                        }
                    )
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: activeCheckIn)
                }
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case 0:
                        friendsListView
                    case 1:
                        friendRequestsView
                    default:
                        friendsListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: BarkParkDesign.Spacing.sm) {
                        Button(action: {
                            showingQRScanner = true
                        }) {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        }
                        
                        Button(action: {
                            showingQRDisplay = true
                        }) {
                            Image(systemName: "qrcode")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        }
                        
                        Button(action: {
                            showingUserSearch = true
                        }) {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refreshAll()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingUserSearch) {
                UserSearchView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingQRDisplay) {
                QRCodeDisplayView()
            }
            .fullScreenCover(isPresented: $showingQRScanner) {
                QRCodeScannerView(socialViewModel: viewModel)
            }
            .onAppear {
                Task {
                    await parksViewModel.loadActiveCheckIns()
                }
            }
        }
    }
    
    private var customTabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Friends", index: 0, count: viewModel.friends.count)
            tabButton(title: "Requests", index: 1, count: viewModel.receivedRequests.count)
        }
        .padding(.horizontal, BarkParkDesign.Spacing.md)
        .padding(.vertical, BarkParkDesign.Spacing.sm)
        .background(BarkParkDesign.Colors.background)
    }
    
    private func tabButton(title: String, index: Int, count: Int) -> some View {
        Button(action: {
            selectedTab = index
        }) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(BarkParkDesign.Typography.headline)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BarkParkDesign.Colors.dogPrimary)
                            .clipShape(Capsule())
                    }
                }
                
                Rectangle()
                    .fill(selectedTab == index ? BarkParkDesign.Colors.dogPrimary : Color.clear)
                    .frame(height: 2)
            }
        }
        .foregroundColor(selectedTab == index ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.secondaryText)
        .frame(maxWidth: .infinity)
    }
    
    private var friendsListView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.friends.isEmpty {
                emptyFriendsView
            } else {
                friendsList
            }
        }
    }
    
    private var friendRequestsView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.receivedRequests.isEmpty {
                emptyRequestsView
            } else {
                requestsList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: BarkParkDesign.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading...")
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text("No Friends Yet")
                    .font(BarkParkDesign.Typography.title2)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("Start connecting with other dog owners! Tap the + button to search for friends.")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
            }
            
            Button("Find Friends") {
                showingUserSearch = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(BarkParkDesign.Colors.dogPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyRequestsView: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary.opacity(0.5))
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text("No Friend Requests")
                    .font(BarkParkDesign.Typography.title2)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("When someone sends you a friend request, you'll see it here.")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BarkParkDesign.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var friendsList: some View {
        List(viewModel.friends) { friend in
            FriendRowView(friend: friend, viewModel: viewModel)
        }
        .listStyle(PlainListStyle())
    }
    
    private var requestsList: some View {
        List(viewModel.receivedRequests) { request in
            FriendRequestRowView(request: request, viewModel: viewModel)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Friend Row View
struct FriendRowView: View {
    let friend: Friend
    let viewModel: SocialViewModel
    @State private var showingRemoveAlert = false
    
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.md) {
            // Profile Image Placeholder
            Circle()
                .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(friend.friend.firstName.prefix(1))
                        .font(BarkParkDesign.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.friend.fullName)
                    .font(BarkParkDesign.Typography.headline)
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("Friends since \(formatDate(friend.friendshipCreatedAt))")
                    .font(BarkParkDesign.Typography.caption)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                showingRemoveAlert = true
            }) {
                Image(systemName: "person.badge.minus")
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, BarkParkDesign.Spacing.xs)
        .alert("Remove Friend", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                Task {
                    await viewModel.removeFriend(friend)
                }
            }
        } message: {
            Text("Are you sure you want to remove \(friend.friend.firstName) from your friends?")
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Friend Request Row View
struct FriendRequestRowView: View {
    let request: FriendRequest
    let viewModel: SocialViewModel
    
    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.sm) {
            HStack(spacing: BarkParkDesign.Spacing.md) {
                // Profile Image Placeholder
                Circle()
                    .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.otherUser.firstName.prefix(1))
                            .font(BarkParkDesign.Typography.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.otherUser.fullName)
                        .font(BarkParkDesign.Typography.headline)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text("Sent you a friend request")
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    
                    Text(request.formattedDate)
                        .font(BarkParkDesign.Typography.caption)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            HStack(spacing: BarkParkDesign.Spacing.sm) {
                Button("Accept") {
                    Task {
                        await viewModel.acceptFriendRequest(request)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(BarkParkDesign.Colors.dogPrimary)
                
                Button("Decline") {
                    Task {
                        await viewModel.declineFriendRequest(request)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
                
                Spacer()
            }
        }
        .padding(.vertical, BarkParkDesign.Spacing.xs)
    }
}

#Preview {
    SocialView()
}