import SwiftUI

struct CommentView: View {
    let comment: Comment
    let currentUserId: Int
    let onReply: (Comment) -> Void
    let onDelete: (Comment) -> Void
    let depth: Int
    
    @State private var showDeleteAlert = false
    
    private var indentationPadding: CGFloat {
        CGFloat(min(depth, 3)) * 20 // Max 3 levels of indentation
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
            // Comment content
            HStack(alignment: .top, spacing: BarkParkDesign.Spacing.sm) {
                // User avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(comment.user.firstName.prefix(1))
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                    )
                
                VStack(alignment: .leading, spacing: BarkParkDesign.Spacing.xs) {
                    // Header
                    HStack {
                        Text(comment.user.fullName)
                            .font(BarkParkDesign.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(BarkParkDesign.Colors.primaryText)
                        
                        Text("·")
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Text(comment.timeAgo)
                            .font(BarkParkDesign.Typography.caption)
                            .foregroundColor(BarkParkDesign.Colors.secondaryText)
                        
                        Spacer()
                        
                        // Delete button for own comments
                        if comment.userId == currentUserId {
                            Button(action: { showDeleteAlert = true }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(BarkParkDesign.Colors.secondaryText)
                            }
                        }
                    }
                    
                    // Content
                    Text(comment.content)
                        .font(BarkParkDesign.Typography.body)
                        .foregroundColor(BarkParkDesign.Colors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Reply button
                    if depth < 3 { // Allow replies only up to depth 3
                        Button(action: { onReply(comment) }) {
                            Text("Reply")
                                .font(BarkParkDesign.Typography.caption)
                                .foregroundColor(BarkParkDesign.Colors.dogPrimary)
                        }
                        .padding(.top, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, indentationPadding)
            
            // Nested replies
            if comment.hasReplies {
                ForEach(comment.replies) { reply in
                    CommentView(
                        comment: reply,
                        currentUserId: currentUserId,
                        onReply: onReply,
                        onDelete: onDelete,
                        depth: depth + 1
                    )
                }
            }
        }
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(comment)
            }
        } message: {
            Text("Are you sure you want to delete this comment? This will also delete all replies.")
        }
    }
}