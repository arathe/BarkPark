//
//  ImageProcessorTests.swift
//  BarkParkTests
//
//  Tests for image processing utilities
//

import Testing
import UIKit
import Foundation
@testable import BarkPark

struct ImageProcessorTests {
    
    // MARK: - Image Validation Tests
    
    @Test("Validates PNG image format correctly")
    func testPNGValidation() {
        // 1x1 pixel PNG
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        #expect(ImageProcessor.isValidImageFormat(pngData))
        #expect(ImageProcessor.getImageFormat(pngData) == .png)
    }
    
    @Test("Validates JPEG image format correctly")
    func testJPEGValidation() {
        // Minimal JPEG header
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46])
        
        #expect(ImageProcessor.isValidImageFormat(jpegData))
        #expect(ImageProcessor.getImageFormat(jpegData) == .jpeg)
    }
    
    @Test("Rejects invalid image data")
    func testInvalidImageRejection() {
        let invalidData = Data("not an image".utf8)
        
        #expect(!ImageProcessor.isValidImageFormat(invalidData))
        #expect(ImageProcessor.getImageFormat(invalidData) == .unknown)
    }
    
    @Test("Handles empty data gracefully")
    func testEmptyDataHandling() {
        let emptyData = Data()
        
        #expect(!ImageProcessor.isValidImageFormat(emptyData))
        #expect(ImageProcessor.getImageFormat(emptyData) == .unknown)
    }
    
    // MARK: - Image Resizing Tests
    
    @Test("Resizes large images correctly")
    func testImageResizing() throws {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        let resizedData = ImageProcessor.resizeImage(pngData, maxSize: 512)
        
        #expect(resizedData != nil)
        #expect(resizedData!.count > 0)
    }
    
    @Test("Maintains aspect ratio during resize")
    func testAspectRatioMaintenance() throws {
        // Create a test image programmatically
        let image = createTestImage(width: 200, height: 100)
        let imageData = image.pngData()!
        
        let resizedData = ImageProcessor.resizeImage(imageData, maxSize: 100)
        let resizedImage = UIImage(data: resizedData!)!
        
        // Should maintain 2:1 aspect ratio
        let aspectRatio = resizedImage.size.width / resizedImage.size.height
        #expect(abs(aspectRatio - 2.0) < 0.1) // Allow small tolerance
    }
    
    @Test("Skips resizing for small images")
    func testSkipResizingSmallImages() {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        let resizedData = ImageProcessor.resizeImage(pngData, maxSize: 2048)
        
        // Small image should remain unchanged or very similar in size
        #expect(resizedData != nil)
    }
    
    // MARK: - Image Compression Tests
    
    @Test("Compresses JPEG images to target size")
    func testJPEGCompression() throws {
        // Create a test JPEG image
        let image = createTestImage(width: 100, height: 100)
        let jpegData = image.jpegData(compressionQuality: 1.0)!
        
        let compressedData = ImageProcessor.compressImage(jpegData, targetSizeKB: 50)
        
        #expect(compressedData != nil)
        #expect(compressedData!.count <= jpegData.count)
    }
    
    @Test("Handles compression for PNG images")
    func testPNGCompression() {
        let pngData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==")!
        
        let compressedData = ImageProcessor.compressImage(pngData, targetSizeKB: 10)
        
        #expect(compressedData != nil)
    }
    
    // MARK: - File Size Validation Tests
    
    @Test("Validates file size limits")
    func testFileSizeValidation() {
        let smallData = Data(count: 1024) // 1KB
        let largeData = Data(count: 10 * 1024 * 1024) // 10MB
        
        #expect(ImageProcessor.isValidFileSize(smallData, maxSizeMB: 5))
        #expect(!ImageProcessor.isValidFileSize(largeData, maxSizeMB: 5))
    }
    
    @Test("Calculates file sizes correctly")
    func testFileSizeCalculation() {
        let data = Data(count: 2048) // 2KB
        let sizeKB = ImageProcessor.fileSizeInKB(data)
        
        #expect(sizeKB == 2)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - ImageProcessor Protocol for Testing

protocol ImageProcessorProtocol {
    static func isValidImageFormat(_ data: Data) -> Bool
    static func getImageFormat(_ data: Data) -> ImageFormat
    static func resizeImage(_ data: Data, maxSize: Int) -> Data?
    static func compressImage(_ data: Data, targetSizeKB: Int) -> Data?
    static func isValidFileSize(_ data: Data, maxSizeMB: Int) -> Bool
    static func fileSizeInKB(_ data: Data) -> Int
}

enum ImageFormat {
    case png
    case jpeg
    case unknown
}