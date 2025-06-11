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
    
    private let apiService = APIService.shared
    
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
            
            if let index = dogs.firstIndex(where: { $0.id == dog.id }) {
                dogs[index] = updatedDog
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateDog(_ dogId: Int, _ updateRequest: UpdateDogRequest) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let updatedDog = try await apiService.updateDog(dogId: dogId, updateRequest: updateRequest)
            
            // Update the dog in our local array
            if let index = dogs.firstIndex(where: { $0.id == dogId }) {
                dogs[index] = updatedDog
            }
            
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
            
            // Update the dog in our local array
            if let index = dogs.firstIndex(where: { $0.id == dogId }) {
                dogs[index] = updatedDog
            }
            
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
            
            // Update the dog in our local array
            if let index = dogs.firstIndex(where: { $0.id == dogId }) {
                dogs[index] = updatedDog
            }
            
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
}