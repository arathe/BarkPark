import Foundation
import SwiftUI

/// Shared application state to reduce redundant API calls and provide single source of truth
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var userDogs: [Dog] = []
    @Published var activeCheckIn: CheckIn?
    @Published var nearbyParks: [DogPark] = []
    @Published var friendsList: [User] = []
    @Published var feedPosts: [Post] = []
    @Published var notifications: [Notification] = []
    @Published var unreadNotificationCount: Int = 0
    
    // MARK: - Loading States
    @Published var isLoadingUser = false
    @Published var isLoadingDogs = false
    @Published var isLoadingCheckIn = false
    @Published var isLoadingParks = false
    @Published var isLoadingFriends = false
    @Published var isLoadingFeed = false
    
    // MARK: - Error States
    @Published var userError: String?
    @Published var dogsError: String?
    @Published var checkInError: String?
    @Published var parksError: String?
    
    // MARK: - Cache Management
    private var lastUserFetch: Date?
    private var lastDogsFetch: Date?
    private var lastCheckInFetch: Date?
    private var lastParksFetch: Date?
    private var lastFriendsFetch: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private let apiService = APIService.shared
    
    private init() {}
    
    // MARK: - User Management
    
    func loadCurrentUser(forceRefresh: Bool = false) async {
        guard !isLoadingUser else { return }
        
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastUserFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           currentUser != nil {
            return
        }
        
        isLoadingUser = true
        userError = nil
        
        do {
            currentUser = try await apiService.getCurrentUser()
            lastUserFetch = Date()
        } catch {
            userError = error.localizedDescription
            print("❌ AppState: Failed to load user: \(error)")
        }
        
        isLoadingUser = false
    }
    
    // MARK: - Dogs Management
    
    func loadUserDogs(forceRefresh: Bool = false) async {
        guard !isLoadingDogs else { return }
        
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastDogsFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !userDogs.isEmpty {
            return
        }
        
        isLoadingDogs = true
        dogsError = nil
        
        do {
            userDogs = try await apiService.getDogs()
            lastDogsFetch = Date()
        } catch {
            dogsError = error.localizedDescription
            print("❌ AppState: Failed to load dogs: \(error)")
        }
        
        isLoadingDogs = false
    }
    
    func addDog(_ dog: Dog) {
        userDogs.append(dog)
        lastDogsFetch = Date()
    }
    
    func updateDog(_ dog: Dog) {
        if let index = userDogs.firstIndex(where: { $0.id == dog.id }) {
            userDogs[index] = dog
        }
    }
    
    func deleteDog(id: Int) {
        userDogs.removeAll { $0.id == id }
    }
    
    // MARK: - Check-in Management
    
    func loadActiveCheckIn(forceRefresh: Bool = false) async {
        guard !isLoadingCheckIn else { return }
        
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastCheckInFetch,
           Date().timeIntervalSince(lastFetch) < 60 { // Check-ins refresh more frequently
            return
        }
        
        isLoadingCheckIn = true
        checkInError = nil
        
        do {
            let checkIns = try await apiService.getActiveCheckIns()
            activeCheckIn = checkIns.first
            lastCheckInFetch = Date()
        } catch {
            checkInError = error.localizedDescription
            print("❌ AppState: Failed to load check-ins: \(error)")
        }
        
        isLoadingCheckIn = false
    }
    
    func checkIn(parkId: Int, dogIds: [Int]) async throws {
        let response = try await apiService.checkIn(parkId: parkId, dogIds: dogIds)
        activeCheckIn = response.checkIn
        lastCheckInFetch = Date()
    }
    
    func checkOut() async throws {
        guard let checkInId = activeCheckIn?.id else { return }
        
        _ = try await apiService.checkOut(checkInId: checkInId)
        activeCheckIn = nil
        lastCheckInFetch = Date()
    }
    
    // MARK: - Parks Management
    
    func loadNearbyParks(latitude: Double, longitude: Double, forceRefresh: Bool = false) async {
        guard !isLoadingParks else { return }
        
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastParksFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !nearbyParks.isEmpty {
            return
        }
        
        isLoadingParks = true
        parksError = nil
        
        do {
            nearbyParks = try await apiService.searchParks(latitude: latitude, longitude: longitude, radiusMiles: 10)
            lastParksFetch = Date()
        } catch {
            parksError = error.localizedDescription
            print("❌ AppState: Failed to load parks: \(error)")
        }
        
        isLoadingParks = false
    }
    
    // MARK: - Friends Management
    
    func loadFriends(forceRefresh: Bool = false) async {
        guard !isLoadingFriends else { return }
        
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastFriendsFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !friendsList.isEmpty {
            return
        }
        
        isLoadingFriends = true
        
        do {
            let response = try await apiService.getFriends()
            friendsList = response.friends
            lastFriendsFetch = Date()
        } catch {
            print("❌ AppState: Failed to load friends: \(error)")
        }
        
        isLoadingFriends = false
    }
    
    // MARK: - Feed Management
    
    func loadFeed(forceRefresh: Bool = false) async {
        guard !isLoadingFeed else { return }
        
        isLoadingFeed = true
        
        do {
            let response = try await apiService.getFeed()
            if forceRefresh {
                feedPosts = response.posts
            } else {
                // Append new posts for pagination
                feedPosts.append(contentsOf: response.posts)
            }
        } catch {
            print("❌ AppState: Failed to load feed: \(error)")
        }
        
        isLoadingFeed = false
    }
    
    // MARK: - Notification Management
    
    func loadNotifications() async {
        do {
            let response = try await apiService.getNotifications()
            notifications = response.notifications
            unreadNotificationCount = notifications.filter { !$0.isRead }.count
        } catch {
            print("❌ AppState: Failed to load notifications: \(error)")
        }
    }
    
    func markNotificationAsRead(_ id: Int) async {
        do {
            try await apiService.markNotificationAsRead(notificationId: id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                notifications[index].isRead = true
                unreadNotificationCount = notifications.filter { !$0.isRead }.count
            }
        } catch {
            print("❌ AppState: Failed to mark notification as read: \(error)")
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        lastUserFetch = nil
        lastDogsFetch = nil
        lastCheckInFetch = nil
        lastParksFetch = nil
        lastFriendsFetch = nil
    }
    
    func logout() {
        // Clear all data
        currentUser = nil
        userDogs = []
        activeCheckIn = nil
        nearbyParks = []
        friendsList = []
        feedPosts = []
        notifications = []
        unreadNotificationCount = 0
        
        // Clear cache timestamps
        clearCache()
        
        // Clear auth token
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
}