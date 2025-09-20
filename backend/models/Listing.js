// backend/models/Listing.js

const mongoose = require('mongoose');

const listingSchema = new mongoose.Schema({
  postedBy: {
    type: mongoose.Schema.Types.ObjectId, // Link to a User
    ref: 'User',
    required: true,
  },
  listingType: {
    type: String,
    enum: ['OFFER', 'REQUEST'], // Can only be one of these two values
    required: true,
  },
  description: { // The raw text from the user
    type: String,
    required: true,
  },
  structuredData: { // The data processed by your AI engine
    material: String,
    quantity: Number,
    unit: String,
    frequency: String
  },
  location: { // For now, a simple string. Can be upgraded later.
    type: String,
    required: true,
  },
  geolocation: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [73.8567, 18.5204]
    }
  },
  status: {
    type: String,
    enum: ['open', 'matched', 'closed'],
    default: 'open',
  },
  geolocation: {
    type: {
      type: String, // 'Point'
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [73.8567, 18.5204]
    }
  },
}, {
  timestamps: true
});

module.exports = mongoose.model('Listing', listingSchema);