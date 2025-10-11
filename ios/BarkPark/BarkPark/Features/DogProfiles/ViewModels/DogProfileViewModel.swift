//
//  DogProfileViewModel.swift
//  BarkPark
//
//  Created by Austin Rathe on 6/4/25.
//

import Foundation
import SwiftUI

@MainActor
class DogProfileViewModel: ObservableObject {
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var membershipErrorMessage: String?
    @Published var shareSearchResults: [User] = []
    @Published var isManagingMembers = false

    private let apiService = APIService.shared

    private var currentUserId: Int? {
        let value = UserDefaults.standard.integer(forKey: "user_id")
        return value == 0 ? nil : value
    }
    
    init() {
        // Don't load dogs in init - wait for authentication
    }
    
    func onAuthenticated() {
        loadDogs()
    }
    
    func loadDogs() {
        print("🐕 DogProfileViewModel: Starting loadDogs()")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🐕 DogProfileViewModel: Calling apiService.getDogs()")
                let fetchedDogs = try await apiService.getDogs()
                print("🐕 DogProfileViewModel: Received \(fetchedDogs.count) dogs from API")
                for (index, dog) in fetchedDogs.enumerated() {
                    print("🐕 Dog \(index): id=\(dog.id), name=\(dog.name), breed=\(dog.breed ?? "nil")")
                }
                dogs = fetchedDogs
                print("🐕 DogProfileViewModel: Updated dogs array, now has \(dogs.count) dogs")
            } catch {
                print("🐕 DogProfileViewModel: Error loading dogs: \(error)")
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func updateDogList(with updatedDog: Dog) {
        if let index = dogs.firstIndex(where: { $0.id == updatedDog.id }) {
            dogs[index] = updatedDog
        } else {
            dogs.append(updatedDog)
        }
    }
    
    func createDog(_ dogRequest: CreateDogRequest) async -> Dog? {
        isLoading = true
        errorMessage = nil
        
        do {
            let newDog = try await apiService.createDog(dogRequest)
            dogs.append(newDog)
            isLoading = false
            return newDog
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    func uploadProfileImage(for dog: Dog, imageData: Data) async -> Bool {
        isUploading = true
        errorMessage = nil
        
        // Process image before upload
        guard let processedImageData = ImageProcessor.prepareImageForUpload(imageData) else {
            errorMessage = "Failed to process image"
            isUploading = false
            return false
        }
        
        do {
            let updatedDog = try await apiService.uploadProfileImage(dogId: dog.id, imageData: processedImageData)
            
            // Update the dog in our local array
            if let index = dogs.firstIndex(where: { $0.id == dog.id }) {
                dogs[index] = updatedDog
            }
            
            isUploading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isUploading = false
            return false
        }
    }
    
    func uploadGalleryImages(for dog: Dog, imageDataArray: [Data]) async -> Bool {
        isUploading = true
        errorMessage = nil
        
        // Process all images before upload
        var processedImageData: [Data] = []
        for imageData in imageDataArray {
            guard let processedData = ImageProcessor.prepareImageForUpload(imageData) else {
                errorMessage = "Failed to process one or more images"
                isUploading = false
                return false
            }
            processedImageData.append(processedData)
        }
        
        do {
            let response = try await apiService.uploadGalleryImages(dogId: dog.id, imageDataArray: processedImageData)
            
            // Update the dog in our local array
            if let index = dogs.firstIndex(where: { $0.id == dog.id }) {
                dogs[index] = response.dog
            }
            
            isUploading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isUploading = false
            return false
        }
    }
    
    func refreshDog(_ dog: Dog) async {
        do {
            let updatedDog = try await apiService.getDog(id: dog.id)
            updateDogList(with: updatedDog)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateDog(_ dogId: Int, _ updateRequest: UpdateDogRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedDog = try await apiService.updateDog(dogId: dogId, updateRequest: updateRequest)
            updateDogList(with: updatedDog)

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func setProfileImageFromGallery(dogId: Int, imageUrl: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedDog = try await apiService.setProfileImageFromGallery(dogId: dogId, imageUrl: imageUrl)
            updateDogList(with: updatedDog)

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func removeGalleryImage(dogId: Int, imageUrl: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedDog = try await apiService.removeGalleryImage(dogId: dogId, imageUrl: imageUrl)
            updateDogList(with: updatedDog)

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func deleteDog(_ dog: Dog) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteDog(id: dog.id)

            // Remove the dog from our local array
            dogs.removeAll { $0.id == dog.id }

            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    // MARK: - Ownership Helpers

    func owners(for dog: Dog) -> [DogOwnerSummary] {
        dog.owners
    }

    func canEdit(dog: Dog) -> Bool {
        guard !isPendingInvite(for: dog), let role = dog.currentUserRole else { return false }
        return role.canEditProfile
    }

    func canDelete(dog: Dog) -> Bool {
        guard !isPendingInvite(for: dog), let role = dog.currentUserRole else { return false }
        return role.canDeleteProfile
    }

    func canManageMembers(dog: Dog) -> Bool {
        guard !isPendingInvite(for: dog), let role = dog.currentUserRole else { return false }
        return role.canManageMembers
    }

    func isPendingInvite(for dog: Dog) -> Bool {
        guard let currentUserId else { return false }
        return dog.ownerSummary(for: currentUserId)?.isPending ?? false
    }

    func membershipIdForCurrentUser(for dog: Dog) -> Int? {
        guard let currentUserId else { return nil }
        return dog.ownerSummary(for: currentUserId)?.membershipId
    }

    func canRemove(member: DogOwnerSummary, from dog: Dog) -> Bool {
        guard canManageMembers(dog: dog) else { return false }
        guard let currentUserId else { return false }

        if member.id == currentUserId {
            return false
        }

        switch member.role {
        case .owner:
            // Only owners can remove other owners
            return dog.ownerSummary(for: currentUserId)?.role == .owner
        case .coOwner, .caretaker, .viewer, .unknown:
            return true
        }
    }

    func isMemberActive(_ member: DogOwnerSummary) -> Bool {
        member.status == .active
    }

    // MARK: - Membership Management

    func refreshMembers(for dog: Dog) async {
        membershipErrorMessage = nil
        isManagingMembers = true

        do {
            let response = try await apiService.getDogMembers(dogId: dog.id)
            updateDogList(with: response.dog)
        } catch {
            membershipErrorMessage = error.localizedDescription
        }

        isManagingMembers = false
    }

    func inviteMember(to dog: Dog, userId: Int, role: DogOwnershipRole) async -> Bool {
        membershipErrorMessage = nil
        isManagingMembers = true

        do {
            let response = try await apiService.inviteDogMember(dogId: dog.id, userId: userId, role: role)
            updateDogList(with: response.dog)
            isManagingMembers = false
            return true
        } catch {
            membershipErrorMessage = error.localizedDescription
            isManagingMembers = false
            return false
        }
    }

    func respondToInvite(for dog: Dog, membershipId: Int, accept: Bool) async -> Bool {
        membershipErrorMessage = nil
        isManagingMembers = true

        do {
            let response = try await apiService.respondToDogInvite(dogId: dog.id, membershipId: membershipId, accept: accept)
            updateDogList(with: response.dog)
            isManagingMembers = false
            return true
        } catch {
            membershipErrorMessage = error.localizedDescription
            isManagingMembers = false
            return false
        }
    }

    func removeMember(_ member: DogOwnerSummary, from dog: Dog) async -> Bool {
        membershipErrorMessage = nil
        isManagingMembers = true

        do {
            let targetMembershipId = member.membershipId ?? member.id
            let response = try await apiService.removeDogMember(dogId: dog.id, memberId: targetMembershipId)
            updateDogList(with: response.dog)
            isManagingMembers = false
            return true
        } catch {
            membershipErrorMessage = error.localizedDescription
            isManagingMembers = false
            return false
        }
    }

    func searchShareableUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            shareSearchResults = []
            return
        }

        membershipErrorMessage = nil

        do {
            let response = try await apiService.searchUsers(query: query)
            shareSearchResults = response.users
        } catch {
            membershipErrorMessage = error.localizedDescription
            shareSearchResults = []
        }
    }
}