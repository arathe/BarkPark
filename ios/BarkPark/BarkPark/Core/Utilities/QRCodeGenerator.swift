//
//  QRCodeGenerator.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import UIKit
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    
    private init() {}
    
    /// Generates a QR code for the given user ID
    /// Format: "barkpark://user/{userId}/{timestamp}"
    func generateUserQRCode(userId: Int) -> UIImage? {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Convert to milliseconds
        let qrData = "barkpark://user/\(userId)/\(timestamp)"
        
        return generateQRCode(from: qrData)
    }
    
    /// Generates a QR code image from the given string data
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = string.data(using: .utf8) else {
            print("❌ QRCodeGenerator: Failed to convert string to data")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Medium error correction
        
        guard let ciImage = filter.outputImage else {
            print("❌ QRCodeGenerator: Failed to generate QR code image")
            return nil
        }
        
        // Scale up the QR code for better quality
        let scaleX = 200.0 / ciImage.extent.size.width
        let scaleY = 200.0 / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("❌ QRCodeGenerator: Failed to create CGImage")
            return nil
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        print("✅ QRCodeGenerator: Successfully generated QR code for data: \(string)")
        return uiImage
    }
    
    /// Validates if a QR code string matches the expected BarkPark format
    static func isValidBarkParkQRCode(_ qrData: String) -> Bool {
        let pattern = #"^barkpark://user/\d+/\d+$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: qrData.utf16.count)
        return regex?.firstMatch(in: qrData, options: [], range: range) != nil
    }
    
    /// Extracts user ID from a valid BarkPark QR code
    static func extractUserID(from qrData: String) -> Int? {
        let pattern = #"^barkpark://user/(\d+)/\d+$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: qrData.utf16.count)
        
        guard let match = regex?.firstMatch(in: qrData, options: [], range: range),
              let userIdRange = Range(match.range(at: 1), in: qrData) else {
            return nil
        }
        
        return Int(String(qrData[userIdRange]))
    }
    
    /// Checks if a QR code is expired (older than 5 minutes)
    static func isQRCodeExpired(_ qrData: String) -> Bool {
        let pattern = #"^barkpark://user/\d+/(\d+)$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: qrData.utf16.count)
        
        guard let match = regex?.firstMatch(in: qrData, options: [], range: range),
              let timestampRange = Range(match.range(at: 1), in: qrData),
              let timestamp = Int(String(qrData[timestampRange])) else {
            return true // Consider invalid format as expired
        }
        
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let fiveMinutes = 5 * 60 * 1000
        return (now - timestamp) > fiveMinutes
    }
}