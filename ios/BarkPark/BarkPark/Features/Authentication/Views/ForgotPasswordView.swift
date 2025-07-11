import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var viewModel = PasswordResetViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var shouldDismissAll = false
    
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
                            Image(systemName: "key.fill")
                                .font(.system(size: 60))
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            
                            Text("Forgot Password?")
                                .font(BarkParkDesign.Typography.title)
                                .foregroundColor(BarkParkDesign.Colors.primaryText)
                            
                            Text("Enter your email address and we'll send you a reset code")
                                .font(BarkParkDesign.Typography.body)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, BarkParkDesign.Spacing.xl)
                        
                        // Email input
                        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.sm) {
                            Text("Email Address")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            
                            TextField("your@email.com", text: $viewModel.email)
                                .textFieldStyle(BarkParkTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(viewModel.showResetTokenView)
                        }
                        .padding(.horizontal)
                        
                        // Error/Success messages
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        if let successMessage = viewModel.successMessage {
                            VStack(spacing: BarkParkDesign.Spacing.md) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(successMessage)
                                        .font(BarkParkDesign.Typography.body)
                                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(BarkParkDesign.CornerRadius.medium)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Send Reset Code button
                        if !viewModel.showResetTokenView {
                            Button(action: {
                                Task {
                                    await viewModel.requestPasswordReset()
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                } else {
                                    Text("Send Reset Code")
                                        .font(BarkParkDesign.Typography.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                            }
                            .background(viewModel.isValidEmail ? BarkParkDesign.Colors.dogPrimary : Color.gray)
                            .cornerRadius(BarkParkDesign.CornerRadius.large)
                            .disabled(!viewModel.isValidEmail || viewModel.isLoading)
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showResetTokenView) {
                ResetPasswordView(viewModel: viewModel, shouldDismissAll: $shouldDismissAll)
            }
            .onChange(of: shouldDismissAll) { newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

// Custom text field style
struct BarkParkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(BarkParkDesign.CornerRadius.medium)
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}