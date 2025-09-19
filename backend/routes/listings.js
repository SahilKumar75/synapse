// backend/routes/listings.js

const express = require('express');
const auth = require('../middleware/auth');
const Listing = require('../models/Listing');
const axios = require('axios'); // For calling the AI service

const router = express.Router();

// @route   POST api/listings
// @desc    Create a new listing (with AI processing)
// @access  Private
router.post('/', auth, async (req, res) => {
  try {
    const { description, location } = req.body;

    // --- AI INTEGRATION ---
    let structuredData = {};
    try {
      // Call the Python AI service
      const aiResponse = await axios.post('http://127.0.0.1:5002/process', {
        description: description
      });
      structuredData = aiResponse.data;
    } catch (aiError) {
      console.error("AI Service Error:", aiError.message);
      // If AI fails, proceed without structured data. Don't block the listing.
    }
    // --------------------

    const newListing = new Listing({
      description,
      location,
      postedBy: req.user.id,
      structuredData: structuredData, // Save the AI's response
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