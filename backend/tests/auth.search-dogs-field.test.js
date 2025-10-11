const request = require('supertest');
const express = require('express');
const cors = require('cors');
const authRoutes = require('../routes/auth');
const Dog = require('../models/Dog');

// Local helper to spin a minimal app that mounts auth routes
const createTestApp = () => {
  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api/auth', authRoutes);
  return app;
};

describe('Auth search returns dog summaries', () => {
  let app;
  let authToken;

  beforeEach(async () => {
    app = createTestApp();

    // Create a user that will execute the search
    const me = {
      email: 'search.client@example.com',
      password: 'password123',
      firstName: 'Search',
      lastName: 'Client'
    };
    const meRes = await request(app)
      .post('/api/auth/register')
      .send(me)
      .expect(201);
    authToken = meRes.body.token;
  });

  it('includes dogs array when searching by owner name', async () => {
    // Create an owner with a dog
    const owner = {
      email: 'owner.withdog@example.com',
      password: 'password123',
      firstName: 'GusOwner',
      lastName: 'Example'
    };
    const ownerRes = await request(app)
      .post('/api/auth/register')
      .send(owner)
      .expect(201);

    const ownerId = ownerRes.body.user.id;
    const dogName = 'Gus';
    await Dog.create({ userId: ownerId, name: dogName, breed: 'Mixed' });

    // Search by owner name; route must still include dogs[] for each returned user
    const res = await request(app)
      .get('/api/auth/search')
      .set('Authorization', `Bearer ${authToken}`)
      .query({ q: 'GusOwner' })
      .expect(200);

    const hit = res.body.users.find(u => u.id === ownerId);
    expect(hit).toBeDefined();
    expect(Array.isArray(hit.dogs)).toBe(true);
    expect(hit.dogs.length).toBeGreaterThanOrEqual(1);
    expect(hit.dogs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ name: dogName, id: expect.any(Number) })
      ])
    );
  });
});

