//
//  QRCodeScanner.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import Foundation
import AVFoundation
import UIKit

protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanner(_ scanner: QRCodeScanner, didDetectQRCode qrCode: String)
    func qrCodeScanner(_ scanner: QRCodeScanner, didFailWithError error: QRScannerError)
}

enum QRScannerError: Error, LocalizedError {
    case cameraUnavailable
    case cameraPermissionDenied
    case scanningFailed
    case invalidQRCode
    
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .cameraPermissionDenied:
            return "Camera permission is required to scan QR codes"
        case .scanningFailed:
            return "Failed to initialize QR code scanner"
        case .invalidQRCode:
            return "Invalid QR code format"
        }
    }
}

class QRCodeScanner: NSObject {
    weak var delegate: QRCodeScannerDelegate?
    var onQRCodeDetected: ((String) -> Void)?
    var onError: ((QRScannerError) -> Void)?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = false
    
    override init() {
        super.init()
    }
    
    func startScanning(in view: UIView) {
        guard !isScanning else { return }
        
        checkCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupCamera(in: view)
                } else {
                    self?.delegate?.qrCodeScanner(self!, didFailWithError: .cameraPermissionDenied)
                    self?.onError?(.cameraPermissionDenied)
                }
            }
        }
    }
    
    func stopScanning() {
        guard isScanning else { return }
        
        captureSession?.stopRunning()
        previewLayer?.removeFromSuperlayer()
        captureSession = nil
        previewLayer = nil
        isScanning = false
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    private func setupCamera(in view: UIView) {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.qrCodeScanner(self, didFailWithError: .cameraUnavailable)
            onError?(.cameraUnavailable)
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            captureSession = AVCaptureSession()
            guard let captureSession = captureSession else {
                delegate?.qrCodeScanner(self, didFailWithError: .scanningFailed)
                onError?(.scanningFailed)
                return
            }
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                delegate?.qrCodeScanner(self, didFailWithError: .scanningFailed)
                onError?(.scanningFailed)
                return
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                delegate?.qrCodeScanner(self, didFailWithError: .scanningFailed)
                onError?(.scanningFailed)
                return
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
            isScanning = true
            
        } catch {
            delegate?.qrCodeScanner(self, didFailWithError: .scanningFailed)
            onError?(.scanningFailed)
        }
    }
    
    func updatePreviewLayer(frame: CGRect) {
        previewLayer?.frame = frame
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let qrCodeString = metadataObject.stringValue else {
            return
        }
        
        // Validate QR code format
        if QRCodeGenerator.isValidBarkParkQRCode(qrCodeString) {
            // Check if QR code is expired
            if QRCodeGenerator.isQRCodeExpired(qrCodeString) {
                delegate?.qrCodeScanner(self, didFailWithError: .invalidQRCode)
                onError?(.invalidQRCode)
            } else {
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                delegate?.qrCodeScanner(self, didDetectQRCode: qrCodeString)
                onQRCodeDetected?(qrCodeString)
            }
        } else {
            delegate?.qrCodeScanner(self, didFailWithError: .invalidQRCode)
            onError?(.invalidQRCode)
        }
    }
}