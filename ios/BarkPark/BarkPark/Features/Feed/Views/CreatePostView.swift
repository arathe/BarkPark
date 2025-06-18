import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    let onPostCreated: (Post) -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with user info
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    
                    VStack(alignment: .leading) {
                        Text(UserDefaults.standard.string(forKey: "user_name") ?? "User")
                            .font(BarkParkDesign.Typography.headline)
                        
                        Menu {
                            Button(action: { viewModel.visibility = .public }) {
                                Label("Public", systemImage: "globe")
                            }
                            Button(action: { viewModel.visibility = .friends }) {
                                Label("Friends", systemImage: "person.2.fill")
                            }
                            Button(action: { viewModel.visibility = .private }) {
                                Label("Only Me", systemImage: "lock.fill")
                            }
                        } label: {
                            HStack(spacing: BarkParkDesign.Spacing.xs) {
                                Image(systemName: viewModel.visibility == .public ? "globe" : 
                                               viewModel.visibility == .friends ? "person.2.fill" : "lock.fill")
                                Text(viewModel.visibility.rawValue.capitalized)
                                Image(systemName: "chevron.down")
                            }
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .padding(.horizontal, BarkParkDesign.Spacing.sm)
                            .padding(.vertical, BarkParkDesign.Spacing.xs)
                            .background(Color(.systemGray6))
                            .cornerRadius(BarkParkDesign.CornerRadius.small)
                        }
                    }
                    
                    Spacer()
                }
                .padding(BarkParkDesign.Spacing.md)
                
                // Text editor
                ZStack(alignment: .topLeading) {
                    if viewModel.content.isEmpty {
                        Text("What's on your mind?")
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            .padding(.horizontal, BarkParkDesign.Spacing.md)
                            .padding(.vertical, BarkParkDesign.Spacing.sm)
                    }
                    
                    TextEditor(text: $viewModel.content)
                        .font(BarkParkDesign.Typography.body)
                        .padding(.horizontal, BarkParkDesign.Spacing.sm)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .frame(minHeight: 150)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                Text("Photo/Video")
                            }
                        }
                        
                        Spacer()
                        
                        if let checkIn = viewModel.currentCheckIn {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(BarkParkDesign.Colors.dogSecondary)
                                Text(checkIn.parkName)
                                    .lineLimit(1)
                            }
                            .font(BarkParkDesign.Typography.caption)
                        }
                    }
                    .padding(BarkParkDesign.Spacing.md)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await viewModel.createPost()
                            if let newPost = viewModel.createdPost {
                                onPostCreated(newPost)
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.content.isEmpty || viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay(
                viewModel.isLoading ?
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                : nil
            )
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var content = ""
    @Published var visibility: PostVisibility = .friends
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var createdPost: Post?
    @Published var currentCheckIn: CheckInInfo?
    
    private let apiService = APIService.shared
    
    init() {
        // TODO: Check if user is currently checked in
    }
    
    func createPost() async {
        isLoading = true
        errorMessage = nil
        
        let request = CreatePostRequest(
            content: content,
            postType: .status,
            visibility: visibility,
            checkInId: currentCheckIn?.id,
            sharedPostId: nil
        )
        
        do {
            createdPost = try await apiService.createPost(request)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    CreatePostView { _ in }
}