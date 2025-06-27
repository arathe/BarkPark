import XCTest
@testable import BarkPark

final class CommentTests: XCTestCase {
    
    // MARK: - Comment Model Tests
    
    func testCommentDecoding() throws {
        let json = """
        {
            "id": 1,
            "post_id": 123,
            "user_id": 456,
            "content": "This is a test comment",
            "parent_comment_id": null,
            "created_at": "2025-06-27T12:00:00.000Z",
            "updated_at": "2025-06-27T12:00:00.000Z",
            "user": {
                "id": 456,
                "first_name": "John",
                "last_name": "Doe",
                "profile_image_url": "https://example.com/avatar.jpg"
            },
            "replies": []
        }
        """.data(using: .utf8)!
        
        let comment = try JSONDecoder.barkParkDecoder.decode(Comment.self, from: json)
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertEqual(comment.postId, 123)
        XCTAssertEqual(comment.userId, 456)
        XCTAssertEqual(comment.content, "This is a test comment")
        XCTAssertNil(comment.parentCommentId)
        XCTAssertEqual(comment.user.id, 456)
        XCTAssertEqual(comment.user.fullName, "John Doe")
        XCTAssertEqual(comment.replies.count, 0)
        XCTAssertFalse(comment.isReply)
        XCTAssertFalse(comment.hasReplies)
    }
    
    func testNestedCommentDecoding() throws {
        let json = """
        {
            "id": 1,
            "post_id": 123,
            "user_id": 456,
            "content": "Parent comment",
            "parent_comment_id": null,
            "created_at": "2025-06-27T12:00:00.000Z",
            "updated_at": "2025-06-27T12:00:00.000Z",
            "user": {
                "id": 456,
                "first_name": "John",
                "last_name": "Doe",
                "profile_image_url": null
            },
            "replies": [
                {
                    "id": 2,
                    "post_id": 123,
                    "user_id": 789,
                    "content": "Reply to parent",
                    "parent_comment_id": 1,
                    "created_at": "2025-06-27T12:05:00.000Z",
                    "updated_at": "2025-06-27T12:05:00.000Z",
                    "user": {
                        "id": 789,
                        "first_name": "Jane",
                        "last_name": "Smith",
                        "profile_image_url": null
                    },
                    "replies": [
                        {
                            "id": 3,
                            "post_id": 123,
                            "user_id": 456,
                            "content": "Reply to reply",
                            "parent_comment_id": 2,
                            "created_at": "2025-06-27T12:10:00.000Z",
                            "updated_at": "2025-06-27T12:10:00.000Z",
                            "user": {
                                "id": 456,
                                "first_name": "John",
                                "last_name": "Doe",
                                "profile_image_url": null
                            },
                            "replies": []
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let comment = try JSONDecoder.barkParkDecoder.decode(Comment.self, from: json)
        
        XCTAssertEqual(comment.id, 1)
        XCTAssertTrue(comment.hasReplies)
        XCTAssertEqual(comment.replies.count, 1)
        
        let firstReply = comment.replies[0]
        XCTAssertEqual(firstReply.id, 2)
        XCTAssertEqual(firstReply.parentCommentId, 1)
        XCTAssertTrue(firstReply.isReply)
        XCTAssertTrue(firstReply.hasReplies)
        XCTAssertEqual(firstReply.user.fullName, "Jane Smith")
        
        let nestedReply = firstReply.replies[0]
        XCTAssertEqual(nestedReply.id, 3)
        XCTAssertEqual(nestedReply.parentCommentId, 2)
        XCTAssertEqual(nestedReply.content, "Reply to reply")
        XCTAssertFalse(nestedReply.hasReplies)
    }
    
    func testCommentsResponseDecoding() throws {
        let json = """
        {
            "comments": [
                {
                    "id": 1,
                    "post_id": 123,
                    "user_id": 456,
                    "content": "First comment",
                    "parent_comment_id": null,
                    "created_at": "2025-06-27T12:00:00.000Z",
                    "updated_at": "2025-06-27T12:00:00.000Z",
                    "user": {
                        "id": 456,
                        "first_name": "John",
                        "last_name": "Doe",
                        "profile_image_url": null
                    },
                    "replies": []
                }
            ],
            "total": 1
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.barkParkDecoder.decode(CommentsResponse.self, from: json)
        
        XCTAssertEqual(response.comments.count, 1)
        XCTAssertEqual(response.total, 1)
        XCTAssertEqual(response.comments[0].content, "First comment")
    }
    
    func testCommentResponseDecoding() throws {
        let json = """
        {
            "id": 5,
            "post_id": 123,
            "user_id": 456,
            "content": "New comment",
            "parent_comment_id": null,
            "created_at": "2025-06-27T12:30:00.000Z",
            "updated_at": "2025-06-27T12:30:00.000Z"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder.barkParkDecoder.decode(CommentResponse.self, from: json)
        
        XCTAssertEqual(response.id, 5)
        XCTAssertEqual(response.postId, 123)
        XCTAssertEqual(response.userId, 456)
        XCTAssertEqual(response.content, "New comment")
        XCTAssertNil(response.parentCommentId)
    }
    
    // MARK: - CommentViewModel Tests
    
    @MainActor
    func testCommentViewModelInitialization() {
        let viewModel = CommentViewModel(postId: 123)
        
        XCTAssertEqual(viewModel.comments.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.hasMore)
    }
    
    // MARK: - Comment UI Tests
    
    func testCommentTimeAgoFormatting() {
        let comment = Comment(
            id: 1,
            postId: 123,
            userId: 456,
            content: "Test",
            parentCommentId: nil,
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date(),
            user: CommentUser(id: 456, firstName: "John", lastName: "Doe", profileImageUrl: nil),
            replies: []
        )
        
        // Time ago should be something like "1h" or "1 hr"
        XCTAssertFalse(comment.timeAgo.isEmpty)
        XCTAssertTrue(comment.timeAgo.contains("1") || comment.timeAgo.contains("hour"))
    }
    
    func testCommentUserFullName() {
        let user = CommentUser(
            id: 1,
            firstName: "John",
            lastName: "Doe",
            profileImageUrl: nil
        )
        
        XCTAssertEqual(user.fullName, "John Doe")
    }
    
    func testDeleteCommentResponseDecoding() throws {
        let json = """
        {
            "message": "Comment deleted successfully"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(DeleteCommentResponse.self, from: json)
        
        XCTAssertEqual(response.message, "Comment deleted successfully")
    }
}