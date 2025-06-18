import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.posts.isEmpty && !viewModel.isLoading {
                    EmptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.posts) { post in
                                PostCard(post: post, onLike: {
                                    Task {
                                        await viewModel.toggleLike(for: post)
                                    }
                                })
                                .padding(.horizontal, BarkParkDesign.Spacing.md)
                                .padding(.vertical, BarkParkDesign.Spacing.sm)
                                
                                Divider()
                            }
                            
                            if viewModel.isLoading && !viewModel.posts.isEmpty {
                                ProgressView()
                                    .padding(BarkParkDesign.Spacing.lg)
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
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading feed...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
                
                #if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: FeedDebugView()) {
                        Image(systemName: "ladybug")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showCreatePost) {
                CreatePostView { newPost in
                    // Prepend new post to feed
                    viewModel.posts.insert(newPost, at: 0)
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
    }
}

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: BarkParkDesign.Spacing.lg) {
            Image(systemName: "newspaper")
                .font(.system(size: 60))
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
            
            Text("No Posts Yet")
                .font(BarkParkDesign.Typography.headline)
                .foregroundColor(BarkParkDesign.Colors.primaryText)
            
            Text("Follow friends to see their posts here")
                .font(BarkParkDesign.Typography.body)
                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BarkParkDesign.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FeedView()
}