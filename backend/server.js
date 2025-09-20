// backend/server.js

const express = require('express');
const dotenv = require('dotenv');
const mongoose = require('mongoose');
const cors = require('cors')

const userRoutes = require('./routes/users');
const listingRoutes = require('./routes/listings');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5001;

// === FIX ===
// 1. JSON parsing middleware MUST come BEFORE you use your routes.
app.use(cors());
app.use(express.json());

// 2. Now, define your routes.
app.use('/api/users', userRoutes);
app.use('/api/listings', listingRoutes);
const placesRoutes = require('./routes/places');
app.use('/api/places', placesRoutes);
// ===========

// Check if the MONGO_URI is actually loaded
if (!process.env.MONGO_URI) {
  console.error('FATAL ERROR: MONGO_URI is not defined in .env file');
  process.exit(1);
}

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB connected successfully.'))
  .catch(err => console.error('MongoDB connection error:', err));

app.get('/', (req, res) => {
  res.send('Synapse Backend API is running!');
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});