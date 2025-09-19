// backend/routes/listings.js

const express = require('express');
const auth = require('../middleware/auth');
const Listing = require('../models/Listing');
const axios = require('axios');

const router = express.Router();

// CREATE
router.post('/', auth, async (req, res) => {
  try {
    const { description, location } = req.body;
    let structuredData = {};
    try {
      const aiResponse = await axios.post('http://127.0.0.1:5002/process', { description });
      structuredData = aiResponse.data;
    } catch (aiError) {
      console.error("AI Service Error:", aiError.message);
    }
    const newListing = new Listing({
      description,
      location,
      postedBy: req.user.id,
      structuredData,
    });
    const listing = await newListing.save();
    res.status(201).json(listing);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// READ (All)
router.get('/', async (req, res) => {
  try {
    const listings = await Listing.find().populate('postedBy', ['name', 'company']).sort({ createdAt: -1 });
    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// READ (Mine)
router.get('/mine', auth, async (req, res) => {
  try {
    const listings = await Listing.find({ postedBy: req.user.id }).sort({ createdAt: -1 });
    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// UPDATE
router.put('/:id', auth, async (req, res) => {
  try {
    const { description, location } = req.body;
    let listing = await Listing.findById(req.params.id);

    if (!listing) return res.status(404).json({ msg: 'Listing not found' });
    if (listing.postedBy.toString() !== req.user.id) return res.status(401).json({ msg: 'User not authorized' });

    let structuredData = {};
    try {
      const aiResponse = await axios.post('http://127.0.0.1:5002/process', { description });
      structuredData = aiResponse.data;
    } catch (aiError) {
      console.error("AI Service Error:", aiError.message);
    }

    const updatedListing = await Listing.findByIdAndUpdate(
      req.params.id,
      { $set: { description, location, structuredData } },
      { new: true }
    );
    res.json(updatedListing);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});


// DELETE
router.delete('/:id', auth, async (req, res) => {
  try {
    const listing = await Listing.findById(req.params.id);
    if (!listing) return res.status(404).json({ msg: 'Listing not found' });
    if (listing.postedBy.toString() !== req.user.id) return res.status(401).json({ msg: 'User not authorized' });

    await Listing.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Listing removed' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

module.exports = router;