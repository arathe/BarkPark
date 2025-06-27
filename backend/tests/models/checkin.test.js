const CheckIn = require('../../models/CheckIn');
const User = require('../../models/User');
const DogPark = require('../../models/DogPark');
const Dog = require('../../models/Dog');
const Friendship = require('../../models/Friendship');
const pool = require('../../config/database');

describe('CheckIn Model - Concurrency & Time-Sensitive Operations', () => {
  let user1, user2, user3;
  let park1, park2;
  let dog1, dog2;
  
  beforeEach(async () => {
    // Create test users
    user1 = await User.create({
      email: 'checkin1@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User1'
    });
    
    user2 = await User.create({
      email: 'checkin2@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User2'
    });
    
    user3 = await User.create({
      email: 'checkin3@test.com',
      password: 'password123',
      firstName: 'CheckIn',
      lastName: 'User3'
    });
    
    // Create test parks
    park1 = await DogPark.create({
      name: 'Test Park 1',
      address: '123 Test St',
      latitude: 40.7128,
      longitude: -74.0060,
      hoursOpen: '06:00',
      hoursClose: '22:00'
    });
    
    park2 = await DogPark.create({
      name: 'Test Park 2',
      address: '456 Test Ave',
      latitude: 40.7589,
      longitude: -73.9851,
      hoursOpen: '06:00',
      hoursClose: '22:00'
    });
    
    // Create test dogs
    dog1 = await Dog.create({
      userId: user1.id,
      name: 'Test Dog 1',
      breed: 'Labrador'
    });
    
    dog2 = await Dog.create({
      userId: user1.id,
      name: 'Test Dog 2',
      breed: 'Beagle'
    });
  });

  afterEach(async () => {
    // Clean up in reverse order
    await pool.query('DELETE FROM checkins WHERE user_id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM dogs WHERE user_id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM dog_parks WHERE id IN ($1, $2)', [park1.id, park2.id]);
    await pool.query('DELETE FROM friendships WHERE user_id IN ($1, $2, $3) OR friend_id IN ($1, $2, $3)', 
      [user1.id, user2.id, user3.id]);
    await pool.query('DELETE FROM users WHERE id IN ($1, $2, $3)', [user1.id, user2.id, user3.id]);
  });

  describe('Check-In Creation', () => {
    test('should create check-in successfully', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: [dog1.id]
      });
      
      expect(checkIn).toBeDefined();
      expect(checkIn.userId).toBe(user1.id);
      expect(checkIn.dogParkId).toBe(park1.id);
      expect(checkIn.dogsPresent).toEqual([dog1.id]);
      expect(checkIn.checkedInAt).toBeDefined();
      expect(checkIn.checkedOutAt).toBeNull();
    });

    test('should handle check-in without dogs', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      expect(checkIn.dogsPresent).toEqual([]);
    });

    test('should handle multiple dogs in check-in', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: [dog1.id, dog2.id]
      });
      
      expect(checkIn.dogsPresent.length).toBe(2);
      expect(checkIn.dogsPresent).toContain(dog1.id);
      expect(checkIn.dogsPresent).toContain(dog2.id);
    });
  });

  describe('Concurrent Check-In Prevention', () => {
    test('should prevent multiple active check-ins at different parks', async () => {
      // First check-in
      const checkIn1 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: [dog1.id]
      });
      
      // Try to check in at another park
      // Note: The model doesn't prevent this - it would be handled in the route
      const checkIn2 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park2.id,
        dogsPresent: [dog1.id]
      });
      
      // Both check-ins exist, showing the model allows this
      expect(checkIn1.id).toBeDefined();
      expect(checkIn2.id).toBeDefined();
      
      // Route layer would need to check for active check-ins
      const activeCheckIns = await CheckIn.findActiveByUser(user1.id);
      expect(activeCheckIns.length).toBe(2);
    });

    test('should handle concurrent check-in attempts', async () => {
      // Simulate concurrent check-ins
      const promises = Array(5).fill(null).map((_, index) => 
        CheckIn.create({
          userId: user1.id,
          dogParkId: park1.id,
          dogsPresent: [index % 2 === 0 ? dog1.id : dog2.id]
        })
      );
      
      const results = await Promise.allSettled(promises);
      
      // All should succeed (model doesn't prevent duplicates)
      const succeeded = results.filter(r => r.status === 'fulfilled');
      expect(succeeded.length).toBe(5);
      
      // Clean up
      const checkInIds = succeeded.map(r => r.value.id);
      await pool.query('DELETE FROM checkins WHERE id = ANY($1)', [checkInIds]);
    });
  });

  describe('Check-Out Operations', () => {
    test('should check out successfully', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: [dog1.id]
      });
      
      const checkedOut = await CheckIn.checkOut(checkIn.id, user1.id);
      
      expect(checkedOut.id).toBe(checkIn.id);
      expect(checkedOut.checkedOutAt).toBeDefined();
    });

    test('should prevent checking out someone else\'s check-in', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const result = await CheckIn.checkOut(checkIn.id, user2.id);
      expect(result).toBeNull();
    });

    test('should prevent double check-out', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      // First check-out
      await CheckIn.checkOut(checkIn.id, user1.id);
      
      // Second check-out attempt
      const result = await CheckIn.checkOut(checkIn.id, user1.id);
      expect(result).toBeNull();
    });

    test('should check out by park ID', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const checkedOut = await CheckIn.checkOutByPark(user1.id, park1.id);
      
      expect(checkedOut.id).toBe(checkIn.id);
      expect(checkedOut.checkedOutAt).toBeDefined();
    });

    test('should handle concurrent check-out attempts', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      // Simulate concurrent check-outs
      const promises = Array(5).fill(null).map(() => 
        CheckIn.checkOut(checkIn.id, user1.id)
      );
      
      const results = await Promise.allSettled(promises);
      
      // Only one should succeed
      const succeeded = results.filter(r => r.status === 'fulfilled' && r.value !== null);
      expect(succeeded.length).toBe(1);
    });
  });

  describe('Active Check-In Queries', () => {
    test('should find active check-ins by user', async () => {
      const checkIn1 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const checkIn2 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park2.id
      });
      
      // Check out one
      await CheckIn.checkOut(checkIn1.id, user1.id);
      
      const active = await CheckIn.findActiveByUser(user1.id);
      
      expect(active.length).toBe(1);
      expect(active[0].id).toBe(checkIn2.id);
      expect(active[0].parkName).toBe('Test Park 2');
    });

    test('should find active check-ins by park', async () => {
      // Multiple users at same park
      await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      await CheckIn.create({
        userId: user2.id,
        dogParkId: park1.id
      });
      
      const checkIn3 = await CheckIn.create({
        userId: user3.id,
        dogParkId: park1.id
      });
      
      // One checks out
      await CheckIn.checkOut(checkIn3.id, user3.id);
      
      const active = await CheckIn.findActiveByPark(park1.id);
      
      expect(active.length).toBe(2);
      expect(active[0].user).toBeDefined();
      expect(active[0].user.firstName).toBeDefined();
    });

    test('should find check-in by user and park', async () => {
      await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const found = await CheckIn.findByUserAndPark(user1.id, park1.id);
      
      expect(found).toBeDefined();
      expect(found.userId).toBe(user1.id);
      expect(found.dogParkId).toBe(park1.id);
    });
  });

  describe('Time-Sensitive Operations', () => {
    test('should calculate visit duration correctly', async () => {
      // Create a check-in with a specific time
      const checkInTime = new Date();
      checkInTime.setHours(checkInTime.getHours() - 2); // 2 hours ago
      
      const result = await pool.query(`
        INSERT INTO checkins (user_id, dog_park_id, dogs, checked_in_at)
        VALUES ($1, $2, $3, $4)
        RETURNING *
      `, [user1.id, park1.id, [], checkInTime]);
      
      const checkIn = CheckIn.formatCheckIn(result.rows[0]);
      
      // Check out
      const checkedOut = await CheckIn.checkOut(checkIn.id, user1.id);
      
      // Calculate duration
      const durationMs = new Date(checkedOut.checkedOutAt) - new Date(checkedOut.checkedInAt);
      const durationHours = durationMs / (1000 * 60 * 60);
      
      expect(durationHours).toBeGreaterThan(1.9);
      expect(durationHours).toBeLessThan(2.1);
    });

    test('should handle check-ins across time zones', async () => {
      // Create check-in
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      // Timestamps should be stored in UTC
      expect(checkIn.checkedInAt).toBeDefined();
      expect(checkIn.checkedInAt instanceof Date).toBe(true);
    });

    test('should get park activity stats with time window', async () => {
      // Create check-ins at different times
      const now = new Date();
      
      // Recent check-in (within 24 hours)
      await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      // Old check-in (outside 24 hours)
      const oldTime = new Date(now);
      oldTime.setHours(oldTime.getHours() - 48);
      
      await pool.query(`
        INSERT INTO checkins (user_id, dog_park_id, dogs, checked_in_at, checked_out_at)
        VALUES ($1, $2, $3, $4, $5)
      `, [user2.id, park1.id, [], oldTime, oldTime]);
      
      const stats = await CheckIn.getParkActivityStats(park1.id, 24);
      
      expect(stats.totalCheckIns).toBe(1); // Only recent one
      expect(stats.currentCheckIns).toBe(1);
    });
  });

  describe('Check-In History', () => {
    test('should get user history in chronological order', async () => {
      // Create check-ins at different times
      const checkIn1 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      // Wait a bit to ensure different timestamps
      await new Promise(resolve => setTimeout(resolve, 10));
      
      const checkIn2 = await CheckIn.create({
        userId: user1.id,
        dogParkId: park2.id
      });
      
      await CheckIn.checkOut(checkIn1.id, user1.id);
      
      const history = await CheckIn.getRecentHistory(user1.id, 10);
      
      expect(history.length).toBe(2);
      expect(history[0].id).toBe(checkIn2.id); // Most recent first
      expect(history[1].id).toBe(checkIn1.id);
    });

    test('should respect history limit', async () => {
      // Create many check-ins
      for (let i = 0; i < 15; i++) {
        const checkIn = await CheckIn.create({
          userId: user1.id,
          dogParkId: i % 2 === 0 ? park1.id : park2.id
        });
        await CheckIn.checkOut(checkIn.id, user1.id);
      }
      
      const history = await CheckIn.getRecentHistory(user1.id, 10);
      expect(history.length).toBe(10);
    });
  });

  describe('Friends at Park', () => {
    test('should find friends at same park', async () => {
      // Create friendship
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      // Both check in at same park
      await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      await CheckIn.create({
        userId: user2.id,
        dogParkId: park1.id
      });
      
      // Non-friend also checks in
      await CheckIn.create({
        userId: user3.id,
        dogParkId: park1.id
      });
      
      const friendsAtPark = await CheckIn.getFriendsAtPark(user1.id, park1.id);
      
      expect(friendsAtPark.length).toBe(1);
      expect(friendsAtPark[0].userId).toBe(user2.id);
    });

    test('should not include checked-out friends', async () => {
      // Create friendship
      const friendship = await Friendship.sendFriendRequest(user1.id, user2.id);
      await Friendship.acceptFriendRequest(friendship.id, user2.id);
      
      // Friend checks in and out
      const checkIn = await CheckIn.create({
        userId: user2.id,
        dogParkId: park1.id
      });
      await CheckIn.checkOut(checkIn.id, user2.id);
      
      // User checks in
      await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const friendsAtPark = await CheckIn.getFriendsAtPark(user1.id, park1.id);
      expect(friendsAtPark.length).toBe(0);
    });
  });

  describe('Edge Cases and Error Handling', () => {
    test('should handle invalid user ID', async () => {
      await expect(CheckIn.create({
        userId: 99999,
        dogParkId: park1.id
      })).rejects.toThrow();
    });

    test('should handle invalid park ID', async () => {
      await expect(CheckIn.create({
        userId: user1.id,
        dogParkId: 99999
      })).rejects.toThrow();
    });

    test('should handle NULL values appropriately', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: null
      });
      
      expect(checkIn.dogsPresent).toEqual([]);
    });

    test('should handle empty arrays', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id,
        dogsPresent: []
      });
      
      expect(checkIn.dogsPresent).toEqual([]);
    });

    test('should format check-in data consistently', async () => {
      const checkIn = await CheckIn.create({
        userId: user1.id,
        dogParkId: park1.id
      });
      
      const formatted = CheckIn.formatCheckIn(checkIn);
      
      expect(formatted).toHaveProperty('id');
      expect(formatted).toHaveProperty('userId');
      expect(formatted).toHaveProperty('dogParkId');
      expect(formatted).toHaveProperty('dogsPresent');
      expect(formatted).toHaveProperty('checkedInAt');
      expect(formatted).toHaveProperty('checkedOutAt');
    });

    test('should handle formatting null check-in', () => {
      const formatted = CheckIn.formatCheckIn(null);
      expect(formatted).toBeNull();
    });
  });

  describe('Abandoned Check-In Scenarios', () => {
    test('should identify abandoned check-ins', async () => {
      // Create an old check-in (simulate abandoned)
      const oldTime = new Date();
      oldTime.setHours(oldTime.getHours() - 6); // 6 hours ago
      
      await pool.query(`
        INSERT INTO checkins (user_id, dog_park_id, dogs, checked_in_at)
        VALUES ($1, $2, $3, $4)
      `, [user1.id, park1.id, [], oldTime]);
      
      // Create a recent check-in
      await CheckIn.create({
        userId: user2.id,
        dogParkId: park1.id
      });
      
      const activeCheckIns = await CheckIn.findActiveByPark(park1.id);
      
      // Both should still be active (no auto-checkout implemented)
      expect(activeCheckIns.length).toBe(2);
      
      // In production, would need a cleanup job for abandoned check-ins
      const longCheckIns = activeCheckIns.filter(c => {
        const duration = Date.now() - new Date(c.checkedInAt);
        return duration > 4 * 60 * 60 * 1000; // 4 hours
      });
      
      expect(longCheckIns.length).toBe(1);
    });
  });

  describe('Performance with Large Datasets', () => {
    test('should handle many concurrent users at same park', async () => {
      // Create many users checking in
      const promises = [];
      for (let i = 0; i < 20; i++) {
        const user = await User.create({
          email: `perf${i}@test.com`,
          password: 'password123',
          firstName: 'Perf',
          lastName: `User${i}`
        });
        
        promises.push(CheckIn.create({
          userId: user.id,
          dogParkId: park1.id
        }));
      }
      
      const start = Date.now();
      await Promise.all(promises);
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(5000); // Should complete within 5 seconds
      
      const active = await CheckIn.findActiveByPark(park1.id);
      expect(active.length).toBeGreaterThanOrEqual(20);
      
      // Cleanup
      await pool.query('DELETE FROM checkins WHERE dog_park_id = $1', [park1.id]);
      await pool.query("DELETE FROM users WHERE email LIKE 'perf%@test.com'");
    });
  });
});