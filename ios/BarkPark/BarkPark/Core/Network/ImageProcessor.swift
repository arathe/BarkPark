//
//  ImageProcessor.swift
//  BarkPark
//
//  Image processing utility for photo uploads
//  Handles resize, compression, and validation
//

import UIKit
import SwiftUI

struct ImageProcessor {
    
    // MARK: - Constants
    static let maxImageSize: CGFloat = 1024
    static let targetSizeBytes: Int = 3 * 1024 * 1024 // 3MB target (accounts for multipart overhead)
    static let compressionQuality: CGFloat = 0.8
    static let supportedFormats: Set<String> = ["public.jpeg", "public.png", "public.webp"]
    
    // MARK: - Main Processing Method
    static func prepareImageForUpload(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else {
            print("❌ ImageProcessor: Failed to create UIImage from data")
            return nil
        }
        
        // Validate image format
        guard isValidImageFormat(data) else {
            print("❌ ImageProcessor: Unsupported image format")
            return nil
        }
        
        // Resize image if needed
        let resizedImage = resizeImageIfNeeded(image)
        
        // Compress image to target size
        guard let compressedData = compressImage(resizedImage) else {
            print("❌ ImageProcessor: Failed to compress image")
            return nil
        }
        
        print("✅ ImageProcessor: Image processed successfully")
        print("   Original size: \(data.count) bytes")
        print("   Final size: \(compressedData.count) bytes")
        print("   Compression ratio: \(String(format: "%.1f", Double(compressedData.count) / Double(data.count) * 100))%")
        
        return compressedData
    }
    
    // MARK: - Validation
    static func isValidImageFormat(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            return false
        }
        
        let typeString = type as String
        return supportedFormats.contains(typeString)
    }
    
    // MARK: - Resize
    static func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let currentSize = image.size
        let maxDimension = max(currentSize.width, currentSize.height)
        
        // If image is already smaller than max size, return original
        guard maxDimension > maxImageSize else {
            print("📏 ImageProcessor: Image size OK (\(Int(maxDimension))px)")
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = maxImageSize / maxDimension
        let newSize = CGSize(
            width: currentSize.width * ratio,
            height: currentSize.height * ratio
        )
        
        print("📏 ImageProcessor: Resizing from \(Int(currentSize.width))x\(Int(currentSize.height)) to \(Int(newSize.width))x\(Int(newSize.height))")
        
        // Create resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    // MARK: - Compression
    static func compressImage(_ image: UIImage) -> Data? {
        var currentQuality: CGFloat = compressionQuality
        let minQuality: CGFloat = 0.1
        let qualityStep: CGFloat = 0.1
        
        while currentQuality >= minQuality {
            guard let imageData = image.jpegData(compressionQuality: currentQuality) else {
                print("❌ ImageProcessor: Failed to create JPEG data")
                return nil
            }
            
            print("🗜️ ImageProcessor: Trying compression quality \(String(format: "%.1f", currentQuality * 100))% = \(imageData.count) bytes")
            
            if imageData.count <= targetSizeBytes {
                print("✅ ImageProcessor: Compression successful at \(String(format: "%.1f", currentQuality * 100))%")
                return imageData
            }
            
            currentQuality -= qualityStep
        }
        
        // If we still can't get under target size, return the smallest we achieved
        print("⚠️ ImageProcessor: Could not reach target size, using minimum quality")
        return image.jpegData(compressionQuality: minQuality)
    }
    
    // MARK: - Utility Methods
    static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    static func getImageDimensions(_ data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
            return nil
        }
        
        return CGSize(width: width.doubleValue, height: height.doubleValue)
    }
}