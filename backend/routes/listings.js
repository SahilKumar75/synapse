// backend/routes/listings.js

const express = require('express');
const auth = require('../middleware/auth'); // Import the auth middleware
const Listing = require('../models/Listing'); // Import the Listing model

const router = express.Router();

// @route   POST api/listings
// @desc    Create a new listing
// @access  Private (notice 'auth' is added here)
router.post('/', auth, async (req, res) => {
  try {
    const { description, location } = req.body;

    const newListing = new Listing({
      description,
      location,
      postedBy: req.user.id, // Get the user ID from the middleware
    });

    const listing = await newListing.save();
    res.status(201).json(listing);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET api/listings
// @desc    Get all listings
// @access  Public
router.get('/', async (req, res) => {
  try {
    const listings = await Listing.find()
      .populate('postedBy', ['name', 'company']) // Replace user ID with user's name and company
      .sort({ createdAt: -1 }); // Show newest listings first

    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   GET api/listings/mine
// @desc    Get listings for the logged-in user
// @access  Private
router.get('/mine', auth, async (req, res) => {
  try {
    const listings = await Listing.find({ postedBy: req.user.id })
      .sort({ createdAt: -1 });

    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;