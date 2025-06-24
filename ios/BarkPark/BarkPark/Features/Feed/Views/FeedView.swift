import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showCreatePost = false
    @State private var scrollOffset: CGFloat = 0
    @State private var headerOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background gradient
                LinearGradient(
                    colors: [
                        BarkParkDesign.Colors.dogPrimary.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .frame(height: 300)
                
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    EmptyFeedView()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Invisible header for offset tracking
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                            }
                            .frame(height: 0)
                            
                            // Feed content
                            LazyVStack(spacing: BarkParkDesign.Spacing.md) {
                                ForEach(viewModel.posts) { post in
                                    PostCard(post: post, onLike: {
                                        Task {
                                            await viewModel.toggleLike(for: post)
                                        }
                                    })
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                }
                                
                                if viewModel.isLoading && !viewModel.posts.isEmpty {
                                    LoadingIndicator()
                                        .padding(.vertical, BarkParkDesign.Spacing.xl)
                                }
                                
                                if viewModel.hasMore && !viewModel.posts.isEmpty {
                                    Color.clear
                                        .frame(height: 1)
                                        .onAppear {
                                            Task {
                                                await viewModel.loadMore()
                                            }
                                        }
                                }
                            }
                            .padding(.top, BarkParkDesign.Spacing.sm)
                            .padding(.horizontal, BarkParkDesign.Spacing.md)
                            .padding(.bottom, 100) // Space for tab bar
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        withAnimation(.easeOut(duration: 0.1)) {
                            headerOpacity = min(1, max(0, -value / 100))
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    LoadingView()
                }
                
                // Floating header background
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(headerOpacity)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: 100)
                    
                    Divider()
                        .opacity(headerOpacity)
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        withAnimation(BarkParkDesign.Animation.spring) {
                            showCreatePost = true
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.1))
                            )
                    }
                }
                
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: FeedDebugView()) {
                        Image(systemName: "ladybug")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { newPost in
                    withAnimation(BarkParkDesign.Animation.spring) {
                        viewModel.posts.insert(newPost, at: 0)
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task {
            await viewModel.loadFeed()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshFeed"))) { _ in
            Task {
                await viewModel.refresh()
            }
        }
    }
}

struct EmptyFeedView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.xl) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(BarkParkDesign.Colors.dogPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                Image(systemName: "newspaper.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                    .rotationEffect(.degrees(animateIcon ? -5 : 5))
                    .animation(
                        .easeInOut(duration: 3)
                        .repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }
            
            VStack(spacing: BarkParkDesign.Spacing.sm) {
                Text("Your Feed Awaits")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(BarkParkDesign.Colors.primaryText)
                
                Text("Follow friends and check into parks\nto see posts here")
                    .font(BarkParkDesign.Typography.body)
                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            NavigationLink(destination: SocialView()) {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Find Friends")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, BarkParkDesign.Spacing.lg)
                .padding(.vertical, BarkParkDesign.Spacing.md)
                .background(
                    Capsule()
                        .fill(BarkParkDesign.Colors.dogPrimary)
                )
            }
        }
        .padding(BarkParkDesign.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateIcon = true
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(BarkParkDesign.Colors.dogPrimary)
            
            Text("Loading your feed...")
                .font(BarkParkDesign.Typography.subheadline)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.95))
    }
}

struct LoadingIndicator: View {
    var body: some View {
        HStack(spacing: BarkParkDesign.Spacing.sm) {
            ProgressView()
                .tint(BarkParkDesign.Colors.dogPrimary)
            
            Text("Loading more posts...")
                .font(BarkParkDesign.Typography.caption)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
        }
    }
}

// Preference key for scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    FeedView()
}