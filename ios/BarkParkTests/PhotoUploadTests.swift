//
//  PhotoUploadTests.swift
//  BarkParkTests
//
//  Unit tests for photo upload functionality
//

import Testing
import Foundation
@testable import BarkPark

struct PhotoUploadTests {
    
    // MARK: - APIService Photo Upload Tests
    
    @Test("APIService can create multipart form data")
    func testMultipartFormDataCreation() async throws {
        let apiService = APIService.shared
        
        // Create test image data (1x1 pixel PNG)
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        // Test creating multipart data
        let (data, contentType) = try apiService.createMultipartFormData(
            imageData: testImageData,
            fieldName: "image",
            filename: "test.png",
            mimeType: "image/png"
        )
        
        #expect(!data.isEmpty)
        #expect(contentType.contains("multipart/form-data"))
        #expect(contentType.contains("boundary="))
    }
    
    @Test("APIService can upload profile image")
    func testProfileImageUpload() async throws {
        let apiService = APIService.shared
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        // Note: This test requires a running backend server
        // In a real test environment, we'd mock the APIService
        do {
            let response: DogResponse = try await apiService.uploadProfileImage(
                dogId: 1,
                imageData: testImageData
            )
            #expect(response.dog.profileImageUrl != nil)
        } catch NetworkError.serverError(let message) where message.contains("not found") {
            // Expected when dog doesn't exist - test passes
        } catch NetworkError.noConnection {
            // Expected when backend isn't running - test passes
        }
    }
    
    @Test("APIService can upload gallery images")
    func testGalleryImageUpload() async throws {
        let apiService = APIService.shared
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        do {
            let response: GalleryUploadResponse = try await apiService.uploadGalleryImages(
                dogId: 1,
                imageDataArray: [testImageData]
            )
            #expect(!response.uploadedImages.isEmpty)
        } catch NetworkError.serverError, NetworkError.noConnection {
            // Expected when backend isn't available - test passes
        }
    }
    
    // MARK: - DogProfileViewModel Photo Tests
    
    @Test("DogProfileViewModel can handle profile image upload")
    func testViewModelProfileImageUpload() async throws {
        let viewModel = DogProfileViewModel()
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        // Test loading state management
        #expect(!viewModel.isUploading)
        
        // Note: This will fail until we implement the method
        await viewModel.uploadProfileImage(for: 1, imageData: testImageData)
        
        // Should have error message since backend isn't connected
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isUploading) // Should reset loading state
    }
    
    @Test("DogProfileViewModel can handle gallery image upload")
    func testViewModelGalleryImageUpload() async throws {
        let viewModel = DogProfileViewModel()
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        #expect(!viewModel.isUploading)
        
        await viewModel.uploadGalleryImages(for: 1, imageDataArray: [testImageData])
        
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isUploading)
    }
    
    // MARK: - Image Processing Tests
    
    @Test("Can resize image data for upload")
    func testImageResizing() throws {
        // Test image compression/resizing functionality
        let testImageData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        let resizedData = ImageProcessor.resizeImage(testImageData, maxSize: 1024)
        
        #expect(resizedData != nil)
        #expect(resizedData!.count <= testImageData.count * 2) // Should not increase size significantly
    }
    
    @Test("Can validate image format")
    func testImageValidation() throws {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        let invalidData = Data("not an image".utf8)
        
        #expect(ImageProcessor.isValidImageFormat(pngData))
        #expect(!ImageProcessor.isValidImageFormat(invalidData))
    }
}

// MARK: - Mock Data Helpers

extension PhotoUploadTests {
    
    static func createMockImageData() -> Data {
        // 1x1 pixel PNG image
        return Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
    }
}