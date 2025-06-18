import SwiftUI
import PhotosUI

struct CreatePostView: View {
    let onPostCreated: (Post) -> Void
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreatePostViewModel()
    
    @State private var postText = ""
    @State private var selectedVisibility: PostVisibility = .friends
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isPosting = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    private let maxCharacters = 500
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: BarkParkDesign.Spacing.lg) {
                            // Post composer
                            postComposer
                            
                            // Media preview
                            if !selectedImages.isEmpty {
                                mediaPreview
                            }
                            
                            // Options
                            optionsSection
                        }
                        .padding(.horizontal, BarkParkDesign.Spacing.md)
                        .padding(.vertical, BarkParkDesign.Spacing.lg)
                    }
                    
                    // Bottom toolbar
                    bottomToolbar
                }
            }
            .navigationBarHidden(true)
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            )
            .onChange(of: selectedPhotos) { _ in
                loadSelectedPhotos()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 17))
                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                
                Spacer()
                
                Text("Create Post")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Spacer()
                
                Button(action: createPost) {
                    if isPosting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 50)
                    } else {
                        Text("Post")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(canPost ? .white : .white.opacity(0.6))
                .padding(.horizontal, BarkParkDesign.Spacing.md)
                .padding(.vertical, BarkParkDesign.Spacing.sm)
                .background(
                    Capsule()
                        .fill(canPost ? BarkParkDesign.Colors.dogPrimary : BarkParkDesign.Colors.dogPrimary.opacity(0.5))
                )
                .disabled(!canPost || isPosting)
            }
            .padding(.horizontal, BarkParkDesign.Spacing.md)
            .padding(.vertical, BarkParkDesign.Spacing.sm)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var postComposer: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
            // User info
            HStack(spacing: BarkParkDesign.Spacing.sm) {
                // Profile image placeholder
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                BarkParkDesign.Colors.dogPrimary.opacity(0.3),
                                BarkParkDesign.Colors.dogSecondary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(UserDefaults.standard.string(forKey: "user_name") ?? "You")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: selectedVisibility == .public ? "globe" : selectedVisibility == .friends ? "person.2.fill" : "lock.fill")
                            .font(.system(size: 11))
                        
                        Text(selectedVisibility == .public ? "Public" : selectedVisibility == .friends ? "Friends" : "Only Me")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
                
                Spacer()
            }
            
            // Text editor
            ZStack(alignment: .topLeading) {
                if postText.isEmpty {
                    Text("What's on your mind?")
                        .font(.system(size: 16))
                        .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $postText)
                    .font(.system(size: 16))
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                    .scrollContentBackground(.hidden)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
            }
            .frame(minHeight: 120)
            
            // Character count
            HStack {
                Spacer()
                
                Text("\(postText.count)/\(maxCharacters)")
                    .font(.system(size: 12))
                    .foregroundColor(postText.count > maxCharacters ? .red : BarkParkDesign.Colors.tertiaryText)
            }
        }
        .padding(BarkParkDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                .fill(Color(.systemBackground))
        )
    }
    
    private var mediaPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BarkParkDesign.Spacing.sm) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium))
                        
                        Button(action: {
                            withAnimation(BarkParkDesign.Animation.spring) {
                                selectedImages.remove(at: index)
                                if index < selectedPhotos.count {
                                    selectedPhotos.remove(at: index)
                                }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding(4)
                    }
                }
                
                // Add more photos button
                Button(action: { showingPhotoPicker = true }) {
                    RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.medium)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                Text("Add")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        )
                }
            }
        }
    }
    
    private var optionsSection: some View {
        VStack(spacing: 0) {
            // Visibility selector
            Menu {
                Button(action: { selectedVisibility = .public }) {
                    Label("Public", systemImage: "globe")
                }
                Button(action: { selectedVisibility = .friends }) {
                    Label("Friends", systemImage: "person.2.fill")
                }
                Button(action: { selectedVisibility = .private }) {
                    Label("Only Me", systemImage: "lock.fill")
                }
            } label: {
                HStack {
                    Image(systemName: "eye")
                        .font(.system(size: 18))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        .frame(width: 24)
                    
                    Text("Visibility")
                        .font(.system(size: 16))
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(selectedVisibility == .public ? "Public" : selectedVisibility == .friends ? "Friends" : "Only Me")
                            .font(.system(size: 14))
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                    }
                }
                .padding(BarkParkDesign.Spacing.md)
            }
            
            Divider()
                .padding(.leading, 56)
            
            // Add location (placeholder)
            Button(action: {}) {
                HStack {
                    Image(systemName: "location")
                        .font(.system(size: 18))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        .frame(width: 24)
                    
                    Text("Add Location")
                        .font(.system(size: 16))
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                }
                .padding(BarkParkDesign.Spacing.md)
            }
            
            Divider()
                .padding(.leading, 56)
            
            // Tag friends (placeholder)
            Button(action: {}) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        .frame(width: 24)
                    
                    Text("Tag Friends")
                        .font(.system(size: 16))
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(BarkParkDesign.Colors.tertiaryText)
                }
                .padding(BarkParkDesign.Spacing.md)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                .fill(Color(.systemBackground))
        )
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: BarkParkDesign.Spacing.xl) {
                Button(action: { showingPhotoPicker = true }) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                        Text("Photo")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
                
                Button(action: {}) {
                    VStack(spacing: 4) {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                        Text("Camera")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
                
                Button(action: {}) {
                    VStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 24))
                        Text("Feeling")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                }
            }
            .padding(.vertical, BarkParkDesign.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .offset(y: -keyboardHeight)
        .animation(.easeOut(duration: 0.3), value: keyboardHeight)
    }
    
    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        postText.count <= maxCharacters &&
        !viewModel.isLoading
    }
    
    private func loadSelectedPhotos() {
        Task {
            selectedImages = []
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImages.append(image)
                }
            }
        }
    }
    
    private func createPost() {
        Task {
            isPosting = true
            viewModel.content = postText
            viewModel.visibility = PostVisibility(rawValue: selectedVisibility.rawValue) ?? .friends
            
            await viewModel.createPost()
            
            if let newPost = viewModel.createdPost {
                await MainActor.run {
                    onPostCreated(newPost)
                    dismiss()
                }
            }
            
            isPosting = false
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