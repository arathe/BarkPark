//
//  QRCodeDisplayView.swift
//  BarkPark
//
//  Created by Austin Rathe on 12/6/25.
//

import SwiftUI

struct QRCodeDisplayView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @State private var qrCodeImage: UIImage?
    @State private var isGenerating = false
    @State private var timeRemaining = 300 // 5 minutes in seconds
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: BarkParkDesign.Spacing.xl) {
                // Header
                VStack(spacing: BarkParkDesign.Spacing.md) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    
                    Text("My QR Code")
                        .font(BarkParkDesign.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Text("Others can scan this code to send you a friend request instantly")
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, BarkParkDesign.Spacing.lg)
                }
                
                // QR Code Display
                VStack(spacing: BarkParkDesign.Spacing.lg) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .frame(width: 280, height: 280)
                        
                        if isGenerating {
                            VStack(spacing: BarkParkDesign.Spacing.md) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Generating QR Code...")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                        } else if let qrImage = qrCodeImage {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 240, height: 240)
                        } else {
                            VStack(spacing: BarkParkDesign.Spacing.md) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("Failed to generate QR code")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                        }
                    }
                    
                    // Timer Display
                    if !isGenerating && qrCodeImage != nil {
                        HStack(spacing: BarkParkDesign.Spacing.sm) {
                            Image(systemName: "clock")
                                .foregroundColor(timeRemaining < 60 ? .orange : BarkParkDesign.Colors.dogPrimary)
                            
                            Text("Expires in \(formatTime(timeRemaining))")
                                .font(BarkParkDesign.Typography.callout)
                                .fontWeight(.medium)
                                .foregroundColor(timeRemaining < 60 ? .orange : BarkParkDesign.Colors.primaryText)
                        }
                        .padding(.horizontal, BarkParkDesign.Spacing.md)
                        .padding(.vertical, BarkParkDesign.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: BarkParkDesign.Spacing.md) {
                    Button("Generate New QR Code") {
                        generateQRCode()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(BarkParkDesign.Colors.dogPrimary)
                    .disabled(isGenerating)
                    
                    if let user = authManager.currentUser {
                        Text("Signed in as \(user.fullName)")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                .padding(.bottom, BarkParkDesign.Spacing.lg)
            }
            .padding(BarkParkDesign.Spacing.lg)
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateQRCode()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private func generateQRCode() {
        guard let user = authManager.currentUser else { return }
        
        isGenerating = true
        stopTimer()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let qrImage = QRCodeGenerator.shared.generateUserQRCode(userId: user.id)
            
            DispatchQueue.main.async {
                self.qrCodeImage = qrImage
                self.isGenerating = false
                
                if qrImage != nil {
                    self.startTimer()
                }
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = 300 // Reset to 5 minutes
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                // Auto-generate new QR code when expired
                generateQRCode()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    QRCodeDisplayView()
        .environmentObject(AuthenticationManager())
}