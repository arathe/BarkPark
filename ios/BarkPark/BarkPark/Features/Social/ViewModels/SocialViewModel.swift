//
//  SocialViewModel.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import Foundation
import Combine
import UIKit

@MainActor
class SocialViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var searchQuery = "" {
        didSet {
            if searchQuery.isEmpty {
                searchResults = []
            } else if searchQuery.count >= 2 {
                searchUsers()
            }
        }
    }
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var searchDebouncer = Timer()
    
    init() {
        Task {
            await loadFriends()
            await loadFriendRequests()
        }
    }
    
    // MARK: - Friends Management
    
    func loadFriends() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getFriends()
            friends = response.friends
            print("✅ SocialViewModel: Loaded \(friends.count) friends")
        } catch {
            print("❌ SocialViewModel: Failed to load friends: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadFriendRequests() async {
        do {
            let response = try await apiService.getFriendRequests()
            friendRequests = response.requests
            print("✅ SocialViewModel: Loaded \(friendRequests.count) friend requests")
        } catch {
            print("❌ SocialViewModel: Failed to load friend requests: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func removeFriend(_ friend: Friend) async {
        do {
            let _ = try await apiService.removeFriend(friendId: friend.friend.id)
            friends.removeAll { $0.friend.id == friend.friend.id }
            print("✅ SocialViewModel: Removed friend \(friend.friend.fullName)")
        } catch {
            print("❌ SocialViewModel: Failed to remove friend: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Friend Requests
    
    func sendFriendRequest(to user: User) async {
        do {
            let _ = try await apiService.sendFriendRequest(to: user.id)
            print("✅ SocialViewModel: Sent friend request to \(user.fullName)")
            
            // Provide haptic feedback for success
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Refresh friend requests to show the new sent request
            await loadFriendRequests()
        } catch {
            print("❌ SocialViewModel: Failed to send friend request: \(error)")
            
            // Provide haptic feedback for error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            errorMessage = error.localizedDescription
        }
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async {
        do {
            let _ = try await apiService.acceptFriendRequest(friendshipId: request.friendshipId)
            print("✅ SocialViewModel: Accepted friend request from \(request.otherUser.fullName)")
            
            // Provide haptic feedback for success
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            // Remove from requests and refresh friends list
            friendRequests.removeAll { $0.friendshipId == request.friendshipId }
            await loadFriends()
        } catch {
            print("❌ SocialViewModel: Failed to accept friend request: \(error)")
            
            // Provide haptic feedback for error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            errorMessage = error.localizedDescription
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest) async {
        do {
            let _ = try await apiService.declineFriendRequest(friendshipId: request.friendshipId)
            print("✅ SocialViewModel: Declined friend request from \(request.otherUser.fullName)")
            
            // Provide haptic feedback for action
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Remove from requests
            friendRequests.removeAll { $0.friendshipId == request.friendshipId }
        } catch {
            print("❌ SocialViewModel: Failed to decline friend request: \(error)")
            
            // Provide haptic feedback for error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            errorMessage = error.localizedDescription
        }
    }
    
    func cancelFriendRequest(_ request: FriendRequest) async {
        do {
            let _ = try await apiService.cancelFriendRequest(friendshipId: request.friendshipId)
            print("✅ SocialViewModel: Cancelled friend request to \(request.otherUser.fullName)")
            
            // Remove from requests
            friendRequests.removeAll { $0.friendshipId == request.friendshipId }
        } catch {
            print("❌ SocialViewModel: Failed to cancel friend request: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - User Search
    
    private func searchUsers() {
        guard !searchQuery.isEmpty, searchQuery.count >= 2 else {
            searchResults = []
            return
        }
        
        // Debounce search requests
        searchDebouncer.invalidate()
        searchDebouncer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            Task { @MainActor in
                await self.performSearch()
            }
        }
    }
    
    private func performSearch() async {
        isSearching = true
        
        do {
            let response = try await apiService.searchUsers(query: searchQuery)
            searchResults = response.users
            print("✅ SocialViewModel: Found \(searchResults.count) users for query '\(searchQuery)'")
        } catch {
            print("❌ SocialViewModel: Search failed: \(error)")
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isSearching = false
    }
    
    // MARK: - Utility Methods
    
    func getFriendshipStatus(with user: User) async -> Friendship? {
        do {
            let response = try await apiService.getFriendshipStatus(with: user.id)
            return response.friendship
        } catch {
            print("❌ SocialViewModel: Failed to get friendship status: \(error)")
            return nil
        }
    }
    
    func isAlreadyFriend(_ user: User) -> Bool {
        return friends.contains { $0.friend.id == user.id }
    }
    
    func hasPendingRequest(with user: User) -> FriendRequest? {
        return friendRequests.first { $0.otherUser.id == user.id }
    }
    
    var receivedRequests: [FriendRequest] {
        return friendRequests.filter { $0.requestType == .received }
    }
    
    var sentRequests: [FriendRequest] {
        return friendRequests.filter { $0.requestType == .sent }
    }
    
    func refreshAll() async {
        await loadFriends()
        await loadFriendRequests()
    }
    
    func clearError() {
        errorMessage = nil
    }
}