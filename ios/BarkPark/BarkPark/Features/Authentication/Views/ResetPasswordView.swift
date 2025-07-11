import SwiftUI

struct ResetPasswordView: View {
    @ObservedObject var viewModel: PasswordResetViewModel
    @Binding var shouldDismissAll: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [BarkParkDesign.Colors.dogPrimary.opacity(0.1), Color.white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: BarkParkDesign.Spacing.lg) {
                        // Header
                        VStack(spacing: BarkParkDesign.Spacing.sm) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            
                            Text("Reset Password")
                                .font(BarkParkDesign.Typography.title)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            Text("Enter the code from your email and create a new password")
                                .font(BarkParkDesign.Typography.body)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, BarkParkDesign.Spacing.xl)
                        
                        VStack(spacing: BarkParkDesign.Spacing.md) {
                            // Reset code input
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                                Text("Reset Code")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                
                                TextField("Enter code from email", text: $viewModel.resetToken)
                                    .textFieldStyle(BarkParkTextFieldStyle())
                                    .autocapitalization(.none)
                                    .onChange(of: viewModel.resetToken) { oldValue, newValue in
                                        if newValue.count == 64 { // Expected token length
                                            Task {
                                                await viewModel.verifyToken()
                                            }
                                        }
                                    }
                            }
                            
                            // New password input
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                                Text("New Password")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                
                                HStack {
                                    if showPassword {
                                        TextField("At least 6 characters", text: $viewModel.newPassword)
                                            .textFieldStyle(BarkParkTextFieldStyle())
                                    } else {
                                        SecureField("At least 6 characters", text: $viewModel.newPassword)
                                            .textFieldStyle(BarkParkTextFieldStyle())
                                    }
                                    
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                    }
                                    .padding(.trailing)
                                }
                            }
                            
                            // Confirm password input
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                                Text("Confirm Password")
                                    .font(BarkParkDesign.Typography.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Re-enter password", text: $viewModel.confirmPassword)
                                            .textFieldStyle(BarkParkTextFieldStyle())
                                    } else {
                                        SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                            .textFieldStyle(BarkParkTextFieldStyle())
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                    }
                                    .padding(.trailing)
                                }
                            }
                            
                            // Password requirements
                            VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                                HStack {
                                    Image(systemName: viewModel.isValidPassword ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.isValidPassword ? .green : BarkParkDesign.Colors.secondaryText)
                                        .font(.caption)
                                    Text("At least 6 characters")
                                        .font(BarkParkDesign.Typography.caption)
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                }
                                
                                HStack {
                                    Image(systemName: viewModel.passwordsMatch && !viewModel.newPassword.isEmpty ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewModel.passwordsMatch && !viewModel.newPassword.isEmpty ? .green : BarkParkDesign.Colors.secondaryText)
                                        .font(.caption)
                                    Text("Passwords match")
                                        .font(BarkParkDesign.Typography.caption)
                                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Reset button
                        Button(action: {
                            Task {
                                await viewModel.resetPassword()
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            } else {
                                Text("Reset Password")
                                    .font(BarkParkDesign.Typography.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                            }
                        }
                        .background(viewModel.canSubmitReset ? BarkParkDesign.Colors.dogPrimary : Color.gray)
                        .cornerRadius(BarkParkDesign.CornerRadius.large)
                        .disabled(!viewModel.canSubmitReset || viewModel.isLoading)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        viewModel.showResetTokenView = false
                    }
                }
            }
            .alert("Success!", isPresented: $viewModel.resetComplete) {
                Button("Login") {
                    // Reset the view model
                    viewModel.reset()
                    // Signal to dismiss all sheets
                    shouldDismissAll = true
                    // Dismiss this sheet
                    dismiss()
                }
            } message: {
                Text("Your password has been reset successfully. Please login with your new password.")
            }
        }
    }
}

struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(viewModel: PasswordResetViewModel(), shouldDismissAll: .constant(false))
    }
}