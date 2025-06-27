import SwiftUI

struct CommentsSheetView: View {
    let post: Post
    @StateObject private var viewModel: CommentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var commentText = ""
    @State private var replyingTo: Comment?
    @FocusState private var isCommentFieldFocused: Bool
    
    init(post: Post) {
        self.post = post
        self._viewModel = StateObject(wrappedValue: CommentViewModel(postId: post.id))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if viewModel.isLoading && viewModel.comments.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else if viewModel.comments.isEmpty {
                    Spacer()
                    VStack(spacing: BarkParkDesign.Spacing.md) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        Text("No comments yet")
                            .font(BarkParkDesign.Typography.body)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        Text("Be the first to comment!")
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: BarkParkDesign.Spacing.md) {
                            ForEach(viewModel.comments) { comment in
                                CommentView(
                                    comment: comment,
                                    currentUserId: viewModel.currentUserId,
                                    onReply: { replyingTo = $0 },
                                    onDelete: { viewModel.deleteComment($0) },
                                    depth: 0
                                )
                                .padding(.horizontal)
                                
                                Divider()
                                    .padding(.leading, BarkParkDesign.Spacing.md)
                            }
                            
                            if viewModel.hasMore {
                                Button(action: { viewModel.loadMoreComments() }) {
                                    if viewModel.isLoadingMore {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Load more comments")
                                            .font(BarkParkDesign.Typography.caption)
                                            .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                // Comment input
                VStack(spacing: 0) {
                    if let replyingTo = replyingTo {
                        HStack {
                            Text("Replying to \(replyingTo.user.fullName)")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            
                            Spacer()
                            
                            Button(action: { self.replyingTo = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, BarkParkDesign.Spacing.xs)
                        .background(Color.gray.opacity(0.1))
                    }
                    
                    HStack {
                        TextField("Add a comment...", text: $commentText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .focused($isCommentFieldFocused)
                            .lineLimit(1...5)
                            .padding(.horizontal, BarkParkDesign.Spacing.sm)
                            .padding(.vertical, BarkParkDesign.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: BarkParkDesign.CornerRadius.large)
                                    .fill(Color.gray.opacity(0.1))
                            )
                        
                        Button(action: sendComment) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(commentText.isEmpty ? BarkParkDesign.Colors.secondaryText : BarkParkDesign.Colors.dogPrimary)
                        }
                        .disabled(commentText.isEmpty || viewModel.isSending)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .top
                )
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
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
        .onAppear {
            viewModel.loadComments()
        }
    }
    
    private func sendComment() {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        viewModel.postComment(content: text, parentCommentId: replyingTo?.id)
        commentText = ""
        replyingTo = nil
        isCommentFieldFocused = false
    }
}

// Preview
struct CommentsSheetView_Previews: PreviewProvider {
    static var previews: some View {
        CommentsSheetView(post: Post(
            id: 1,
            userId: 1,
            content: "Test post",
            postType: .status,
            visibility: .friends,
            checkInId: nil,
            sharedPostId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            firstName: "John",
            lastName: "Doe",
            userProfileImage: nil,
            likeCount: 0,
            commentCount: 5,
            userLiked: false,
            media: nil,
            checkIn: nil
        ))
    }
}