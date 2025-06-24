const Friendship = require('../../models/Friendship');
const User = require('../../models/User');
const pool = require('../../config/database');

describe('Friendship Model - State Machine & Bidirectional Relationships', () => {
  let user1, user2, user3, user4;
  
  beforeEach(async () => {
    // Create test users for each test
    user1 = await User.create({
      email: 'friend1@test.com',
      password: 'password123',
      firstName: 'Friend',
      lastName: 'One'
    });
    
    user2 = await User.create({
      email: 'friend2@test.com',
      password: 'password123',
      firstName: 'Friend',
      lastName: 'Two'
    });
    
    user3 = await User.create({
      email: 'friend3@test.com',
      password: 'password123',
      firstName: 'Friend',
      lastName: 'Three'
    });
    
    user4 = await User.create({
      email: 'friend4@test.com',
      password: 'password123',
      firstName: 'Friend',
      lastName: 'Four'
    });
  });

  afterEach(async () => {
    // Clean up in reverse order due to foreign key constraints
    await pool.query('DELETE FROM friendships WHERE requester_id IN ($1, $2, $3, $4) OR addressee_id IN ($1, $2, $3, $4)', 
      [user1.id, user2.id, user3.id, user4.id]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3, $4)', 
      [user1.id, user2.id, user3.id, user4.id]);
  });

  describe('Friend Request Creation', () => {
    test('should successfully send a friend request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      expect(friendship).toBeDefined();
      expect(friendship.requester_id).toBe(user1.id);
      expect(friendship.addressee_id).toBe(user2.id);
      expect(friendship.status).toBe('pending');
      expect(friendship.id).toBeDefined();
    });

    test('should prevent self-friendship', async () => {
      await expect(Friendship.sendFriendRequest(user1.id, user1.id))
        .rejects.toThrow('Cannot send friend request to yourself');
    });

    test('should prevent duplicate friend requests in same direction', async () => {
      await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.sendFriendRequest(user1.id, user2.id))
        .rejects.toThrow('Friendship request already exists or users are already friends');
    });

    test('should prevent duplicate friend requests in opposite direction', async () => {
      await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.sendFriendRequest(user2.id, user1.id))
        .rejects.toThrow('Friendship request already exists or users are already friends');
    });

    test('should handle concurrent friend requests from both users', async () => {
      // Simulate concurrent requests
      const promises = [
        Friendship.sendFriendRequest(user1.id, user2.id),
        Friendship.sendFriendRequest(user2.id, user1.id)
      ];
      
      const results = await Promise.allSettled(promises);
      
      // One should succeed, one should fail
      const succeeded = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');
      
      expect(succeeded.length).toBe(1);
      expect(failed.length).toBe(1);
      expect(failed[0].reason.message).toContain('Friendship request already exists');
    });

    test('should prevent friend request when already friends', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      await expect(Friendship.sendFriendRequest(user1.id, user2.id))
        .rejects.toThrow('Friendship request already exists or users are already friends');
      
      await expect(Friendship.sendFriendRequest(user2.id, user1.id))
        .rejects.toThrow('Friendship request already exists or users are already friends');
    });
  });

  describe('Friend Request Acceptance', () => {
    test('should allow addressee to accept friend request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      const accepted = await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      expect(accepted.status).toBe('accepted');
      expect(accepted.updated_at).toBeDefined();
    });

    test('should prevent requester from accepting their own request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.acceptFriendRequest(friendship.id, user1.id))
        .rejects.toThrow('Friend request not found or not authorized to accept');
    });

    test('should prevent accepting non-existent friend request', async () => {
      await expect(Friendship.acceptFriendRequest(99999, user1.id))
        .rejects.toThrow('Friend request not found or not authorized to accept');
    });

    test('should prevent accepting already accepted request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      await expect(Friendship.acceptFriendRequest(friendship.id, user2.id))
        .rejects.toThrow('Friend request not found or not authorized to accept');
    });

    test('should prevent third party from accepting friend request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.acceptFriendRequest(friendship.id, user3.id))
        .rejects.toThrow('Friend request not found or not authorized to accept');
    });
  });

  describe('Friend Request Declining', () => {
    test('should allow addressee to decline friend request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      const declined = await Friendship.declineFriendRequest(friendship.id, user2.id);
      
      expect(declined.status).toBe('declined');
      expect(declined.updated_at).toBeDefined();
    });

    test('should prevent requester from declining their own request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.declineFriendRequest(friendship.id, user1.id))
        .rejects.toThrow('Friend request not found or not authorized to decline');
    });

    test('should allow new friend request after declining', async () => {
      const friendship1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.declineFriendRequest(friendship1.id, user2.id);
      
      // Should be able to send new request after declining
      const friendship2 = await Friendship.sendFriendRequest(user1.id, user2.id);
      expect(friendship2.status).toBe('pending');
    });
  });

  describe('Friend Request Cancellation', () => {
    test('should allow requester to cancel their pending request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      const result = await Friendship.cancelFriendRequest(friendship.id, user1.id);
      
      expect(result.success).toBe(true);
      
      // Verify it's deleted
      const status = await Friendship.getFriendshipStatus(user1.id, user2.id);
      expect(status).toBeNull();
    });

    test('should prevent addressee from cancelling received request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.cancelFriendRequest(friendship.id, user2.id))
        .rejects.toThrow('Friend request not found or not authorized to cancel');
    });

    test('should prevent cancelling accepted request', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      await expect(Friendship.cancelFriendRequest(friendship.id, user1.id))
        .rejects.toThrow('Friend request not found or not authorized to cancel');
    });
  });

  describe('Bidirectional Friend Queries', () => {
    test('should return same friends list regardless of who initiated friendship', async () => {
      // User1 sends to User2
      const friendship1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship1.id, user2.id);
      
      // User3 sends to User1
      const friendship2 = await Friendship.sendFriendRequest(user3.id, user1.id);
      await Friendship.acceptFriendRequest(friendship2.id, user1.id);
      
      const user1Friends = await Friendship.getFriends(user1.id);
      
      expect(user1Friends.length).toBe(2);
      const friendIds = user1Friends.map(f => f.friend.id).sort();
      expect(friendIds).toEqual([user2.id, user3.id].sort());
    });

    test('should show friendship in both users friends lists', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      const user1Friends = await Friendship.getFriends(user1.id);
      const user2Friends = await Friendship.getFriends(user2.id);
      
      expect(user1Friends.length).toBe(1);
      expect(user2Friends.length).toBe(1);
      expect(user1Friends[0].friend.id).toBe(user2.id);
      expect(user2Friends[0].friend.id).toBe(user1.id);
    });

    test('should correctly identify sent vs received pending requests', async () => {
      // User1 sends to User2
      await Friendship.sendFriendRequest(user1.id, user2.id);
      
      // User3 sends to User1
      await Friendship.sendFriendRequest(user3.id, user1.id);
      
      const user1Pending = await Friendship.getPendingRequests(user1.id);
      
      expect(user1Pending.length).toBe(2);
      
      const sent = user1Pending.filter(r => r.requestType === 'sent');
      const received = user1Pending.filter(r => r.requestType === 'received');
      
      expect(sent.length).toBe(1);
      expect(received.length).toBe(1);
      expect(sent[0].otherUser.id).toBe(user2.id);
      expect(received[0].otherUser.id).toBe(user3.id);
    });
  });

  describe('Friend Removal', () => {
    test('should allow either user to remove friendship', async () => {
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      // User1 removes friendship
      const result1 = await Friendship.removeFriend(user1.id, user2.id);
      expect(result1.success).toBe(true);
      
      // Verify friendship is gone
      const friends1 = await Friendship.getFriends(user1.id);
      const friends2 = await Friendship.getFriends(user2.id);
      expect(friends1.length).toBe(0);
      expect(friends2.length).toBe(0);
      
      // Create new friendship
      const friendship2 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship2.id, user2.id);
      
      // User2 removes friendship
      const result2 = await Friendship.removeFriend(user2.id, user1.id);
      expect(result2.success).toBe(true);
    });

    test('should prevent removing non-existent friendship', async () => {
      await expect(Friendship.removeFriend(user1.id, user2.id))
        .rejects.toThrow('Friendship not found or not authorized to remove');
    });

    test('should prevent removing pending friendship', async () => {
      await Friendship.sendFriendRequest(user1.id, user2.id);
      
      await expect(Friendship.removeFriend(user1.id, user2.id))
        .rejects.toThrow('Friendship not found or not authorized to remove');
    });
  });

  describe('Complex State Transitions', () => {
    test('should handle decline -> new request -> accept flow', async () => {
      // First request declined
      const request1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.declineFriendRequest(request1.id, user2.id);
      
      // Second request sent and accepted
      const request2 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(request2.id, user2.id);
      
      const friends = await Friendship.getFriends(user1.id);
      expect(friends.length).toBe(1);
      expect(friends[0].friend.id).toBe(user2.id);
    });

    test('should handle remove -> new request -> accept flow', async () => {
      // Create and remove friendship
      const request1 = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(request1.id, user2.id);
      await Friendship.removeFriend(user1.id, user2.id);
      
      // Send new request
      const request2 = await Friendship.sendFriendRequest(user2.id, user1.id);
      await Friendship.acceptFriendRequest(request2.id, user1.id);
      
      const friends = await Friendship.getFriends(user1.id);
      expect(friends.length).toBe(1);
    });

    test('should maintain data consistency with multiple friendships', async () => {
      // User1 befriends User2, User3, User4
      const friendships = await Promise.all([
        Friendship.sendFriendRequest(user1.id, user2.id),
        Friendship.sendFriendRequest(user1.id, user3.id),
        Friendship.sendFriendRequest(user4.id, user1.id)
      ]);
      
      // Accept all
      await Promise.all([
        Friendship.acceptFriendRequest(friendships[0].id, user2.id),
        Friendship.acceptFriendRequest(friendships[1].id, user3.id),
        Friendship.acceptFriendRequest(friendships[2].id, user1.id)
      ]);
      
      // Verify counts
      const user1Friends = await Friendship.getFriends(user1.id);
      expect(user1Friends.length).toBe(3);
      
      // Remove one friendship
      await Friendship.removeFriend(user1.id, user3.id);
      
      const user1UpdatedFriends = await Friendship.getFriends(user1.id);
      expect(user1UpdatedFriends.length).toBe(2);
      
      // User3 should have no friends now
      const user3Friends = await Friendship.getFriends(user3.id);
      expect(user3Friends.length).toBe(0);
    });
  });

  describe('Edge Cases and Error Handling', () => {
    test('should handle invalid user IDs gracefully', async () => {
      await expect(Friendship.sendFriendRequest(99999, user1.id))
        .rejects.toThrow();
      
      await expect(Friendship.sendFriendRequest(user1.id, 99999))
        .rejects.toThrow();
    });

    test('should handle NULL values appropriately', async () => {
      await expect(Friendship.sendFriendRequest(null, user1.id))
        .rejects.toThrow();
      
      await expect(Friendship.sendFriendRequest(user1.id, null))
        .rejects.toThrow();
    });

    test('should return empty arrays for users with no friends', async () => {
      const friends = await Friendship.getFriends(user1.id);
      const pending = await Friendship.getPendingRequests(user1.id);
      
      expect(friends).toEqual([]);
      expect(pending).toEqual([]);
    });

    test('should handle rapid state changes correctly', async () => {
      // Send request
      const request = await Friendship.sendFriendRequest(user1.id, user2.id);
      
      // Try to accept and decline simultaneously
      const promises = [
        Friendship.acceptFriendRequest(request.id, user2.id),
        Friendship.declineFriendRequest(request.id, user2.id)
      ];
      
      const results = await Promise.allSettled(promises);
      
      // One should succeed, one should fail
      const succeeded = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');
      
      expect(succeeded.length).toBe(1);
      expect(failed.length).toBe(1);
    });
  });

  describe('Friendship Status Queries', () => {
    test('should correctly report friendship status', async () => {
      // No relationship
      let status = await Friendship.getFriendshipStatus(user1.id, user2.id);
      expect(status).toBeNull();
      
      // Pending
      const request = await Friendship.sendFriendRequest(user1.id, user2.id);
      status = await Friendship.getFriendshipStatus(user1.id, user2.id);
      expect(status.status).toBe('pending');
      
      // Accepted
      await Friendship.acceptFriendRequest(request.id, user2.id);
      status = await Friendship.getFriendshipStatus(user1.id, user2.id);
      expect(status.status).toBe('accepted');
      
      // Check bidirectional
      const reverseStatus = await Friendship.getFriendshipStatus(user2.id, user1.id);
      expect(reverseStatus.id).toBe(status.id);
    });
  });
});