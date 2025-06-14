//
//  QRCodeScannerView.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @ObservedObject var socialViewModel: SocialViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var scanner = QRCodeScanner()
    @State private var isProcessing = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var scanFrameSize: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreviewView(scanner: scanner)
                    .onAppear {
                        scanner.onQRCodeDetected = { qrCode in
                            handleQRCodeDetected(qrCode)
                        }
                        scanner.onError = { error in
                            handleScannerError(error)
                        }
                    }
                    .onDisappear {
                        scanner.stopScanning()
                        scanner.onQRCodeDetected = nil
                        scanner.onError = nil
                    }
                
                // Scanning Overlay
                VStack {
                    // Top section with instructions
                    VStack(spacing: BarkParkDesign.Spacing.md) {
                        Text("Scan QR Code")
                            .font(BarkParkDesign.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Point your camera at a BarkPark QR code to connect")
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, BarkParkDesign.Spacing.lg)
                    }
                    .padding(.top, BarkParkDesign.Spacing.xl)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.7), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(.all, edges: .top)
                    )
                    
                    Spacer()
                    
                    // Scanning Frame
                    ZStack {
                        // Scanning area outline
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.clear)
                            )
                        
                        // Corner markers
                        VStack {
                            HStack {
                                ScannerCorner(corner: .topLeft)
                                Spacer()
                                ScannerCorner(corner: .topRight)
                            }
                            Spacer()
                            HStack {
                                ScannerCorner(corner: .bottomLeft)
                                Spacer()
                                ScannerCorner(corner: .bottomRight)
                            }
                        }
                        .frame(width: 250, height: 250)
                        
                        // Processing indicator
                        if isProcessing {
                            VStack(spacing: BarkParkDesign.Spacing.md) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                                
                                Text("Processing...")
                                    .font(BarkParkDesign.Typography.callout)
                                    .foregroundColor(.white)
                            }
                            .padding(BarkParkDesign.Spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.7))
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom section with tips
                    VStack(spacing: BarkParkDesign.Spacing.sm) {
                        HStack(spacing: BarkParkDesign.Spacing.sm) {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.yellow)
                            Text("Make sure the QR code is well-lit and centered")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        HStack(spacing: BarkParkDesign.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            Text("QR codes expire after 5 minutes")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.bottom, BarkParkDesign.Spacing.xl)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(.all, edges: .bottom)
                    )
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                .padding(BarkParkDesign.Spacing.lg)
            }
            .alert("Success!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    isProcessing = false
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let scanner: QRCodeScanner
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if uiView.layer.sublayers?.isEmpty != false {
            scanner.startScanning(in: uiView)
        }
    }
}

// MARK: - Scanner Corner View
struct ScannerCorner: View {
    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let corner: Corner
    
    var body: some View {
        Path { path in
            let size: CGFloat = 20
            let thickness: CGFloat = 3
            
            switch corner {
            case .topLeft:
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
            case .topRight:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size, y: size))
            case .bottomLeft:
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size, y: size))
            case .bottomRight:
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: size, y: size))
                path.addLine(to: CGPoint(x: size, y: 0))
            }
        }
        .stroke(BarkParkDesign.Colors.dogPrimary, lineWidth: 4)
        .frame(width: 20, height: 20)
    }
}

// MARK: - QR Scanner Event Handling
extension QRCodeScannerView {
    func handleQRCodeDetected(_ qrCode: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        
        Task {
            do {
                let response = try await APIService.shared.connectViaQRCode(qrData: qrCode)
                
                await MainActor.run {
                    successMessage = "Friend request sent to \(response.targetUser.fullName)!"
                    showingSuccess = true
                    
                    // Refresh the social view model
                    Task {
                        await socialViewModel.loadFriendRequests()
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    func handleScannerError(_ error: QRScannerError) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

#Preview {
    QRCodeScannerView(socialViewModel: SocialViewModel())
}