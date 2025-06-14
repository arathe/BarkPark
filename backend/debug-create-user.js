// Debug script to test user creation in production
const express = require('express');
const User = require('./models/User');
require('dotenv').config();

const app = express();
app.use(express.json());

// Debug endpoint to test user creation
app.post('/debug/create-user', async (req, res) => {
  try {
    console.log('Debug: Starting user creation test');
    console.log('Debug: Request body:', req.body);
    
    const { email, password, firstName, lastName } = req.body;
    
    console.log('Debug: Attempting to create user with User.create()');
    const user = await User.create({
      email,
      password, 
      firstName,
      lastName,
      phone: null
    });
    
    console.log('Debug: User created successfully:', user);
    res.json({ success: true, user });
    
  } catch (error) {
    console.error('Debug: Error creating user:');
    console.error('  Message:', error.message);
    console.error('  Stack:', error.stack);
    console.error('  Code:', error.code);
    console.error('  Detail:', error.detail);
    console.error('  Constraint:', error.constraint);
    
    res.status(500).json({ 
      error: 'Failed to create user',
      details: {
        message: error.message,
        code: error.code,
        detail: error.detail
      }
    });
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Debug server running on port ${port}`);
});