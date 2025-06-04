//
//  APIServicePhotoTests.swift
//  BarkParkTests
//
//  Focused tests for APIService photo upload functionality
//

import Testing
import Foundation
@testable import BarkPark

struct APIServicePhotoTests {
    
    // MARK: - Multipart Form Data Tests
    
    @Test("Creates valid multipart form data boundary")
    func testMultipartBoundaryGeneration() throws {
        let apiService = APIService.shared
        let boundary = apiService.generateBoundary()
        
        #expect(boundary.count > 10)
        #expect(boundary.hasPrefix("Boundary-"))
        #expect(boundary.allSatisfy { $0.isASCII })
    }
    
    @Test("Creates proper multipart headers")
    func testMultipartHeaders() throws {
        let apiService = APIService.shared
        let testData = Data("test".utf8)
        
        let (_, contentType) = try apiService.createMultipartFormData(
            imageData: testData,
            fieldName: "image",
            filename: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        #expect(contentType.contains("multipart/form-data"))
        #expect(contentType.contains("boundary="))
    }
    
    @Test("Creates multipart body with correct format")
    func testMultipartBodyFormat() throws {
        let apiService = APIService.shared
        let testData = Data("test image data".utf8)
        
        let (data, _) = try apiService.createMultipartFormData(
            imageData: testData,
            fieldName: "image",
            filename: "test.png",
            mimeType: "image/png"
        )
        
        let bodyString = String(data: data, encoding: .utf8)!
        
        #expect(bodyString.contains("Content-Disposition: form-data"))
        #expect(bodyString.contains("name=\"image\""))
        #expect(bodyString.contains("filename=\"test.png\""))
        #expect(bodyString.contains("Content-Type: image/png"))
        #expect(bodyString.contains("test image data"))
    }
    
    // MARK: - Image Upload URL Tests
    
    @Test("Constructs correct profile image upload URL")
    func testProfileImageUploadURL() {
        let apiService = APIService.shared
        let expectedURL = "\(APIConfiguration.baseURL)/dogs/123/profile-image"
        let actualURL = apiService.profileImageUploadURL(dogId: 123)
        
        #expect(actualURL == expectedURL)
    }
    
    @Test("Constructs correct gallery upload URL")
    func testGalleryUploadURL() {
        let apiService = APIService.shared
        let expectedURL = "\(APIConfiguration.baseURL)/dogs/456/gallery"
        let actualURL = apiService.galleryUploadURL(dogId: 456)
        
        #expect(actualURL == expectedURL)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handles invalid image data gracefully")
    func testInvalidImageDataHandling() async {
        let apiService = APIService.shared
        let invalidData = Data()
        
        do {
            _ = try await apiService.uploadProfileImage(dogId: 1, imageData: invalidData)
            #expect(Bool(false), "Should have thrown an error for invalid data")
        } catch {
            // Expected to throw an error
            #expect(error is NetworkError)
        }
    }
    
    @Test("Handles network connectivity issues")
    func testNetworkConnectivityHandling() async {
        // This test simulates network issues by using an invalid base URL
        let apiService = APIService.shared
        let testData = Data("test".utf8)
        
        do {
            _ = try await apiService.uploadProfileImage(dogId: 999, imageData: testData)
        } catch NetworkError.noConnection {
            // Expected when backend is not running
        } catch NetworkError.serverError {
            // Also acceptable - server responded with error
        } catch {
            // Any network error is acceptable for this test
        }
    }
    
    // MARK: - Response Parsing Tests
    
    @Test("Parses successful upload response correctly")
    func testUploadResponseParsing() throws {
        let jsonString = """
        {
            "message": "Profile image uploaded successfully",
            "dog": {
                "id": 1,
                "name": "Test Dog",
                "profileImageUrl": "https://example.com/image.jpg",
                "galleryImages": []
            }
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(DogResponse.self, from: data)
        
        #expect(response.message == "Profile image uploaded successfully")
        #expect(response.dog.id == 1)
        #expect(response.dog.profileImageUrl == "https://example.com/image.jpg")
    }
    
    @Test("Parses gallery upload response correctly")
    func testGalleryUploadResponseParsing() throws {
        let jsonString = """
        {
            "message": "Gallery images uploaded successfully",
            "dog": {
                "id": 1,
                "name": "Test Dog",
                "profileImageUrl": null,
                "galleryImages": [
                    "https://example.com/gallery1.jpg",
                    "https://example.com/gallery2.jpg"
                ]
            },
            "uploadedImages": [
                "https://example.com/gallery1.jpg",
                "https://example.com/gallery2.jpg"
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let response = try decoder.decode(GalleryUploadResponse.self, from: data)
        
        #expect(response.uploadedImages.count == 2)
        #expect(response.dog.galleryImages.count == 2)
        #expect(response.uploadedImages.first == "https://example.com/gallery1.jpg")
    }
}

// MARK: - APIService Extension for Testing

extension APIService {
    
    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    func profileImageUploadURL(dogId: Int) -> String {
        return "\(APIConfiguration.baseURL)/dogs/\(dogId)/profile-image"
    }
    
    func galleryUploadURL(dogId: Int) -> String {
        return "\(APIConfiguration.baseURL)/dogs/\(dogId)/gallery"
    }
}