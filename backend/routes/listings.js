// backend/routes/listings.js

const express = require('express');
const auth = require('../middleware/auth');
const Listing = require('../models/Listing');
const axios = require('axios');

const router = express.Router();

// Helper function for Geocoding
const geocodeLocation = async (location) => {
  try {
    const response = await axios.get('https://api.opencagedata.com/geocode/v1/json', {
      params: {
        q: location,
        key: process.env.OPENCAGE_API_KEY,
        limit: 1
      }
    });
    if (response.data.results.length > 0) {
      const { lat, lng } = response.data.results[0].geometry;
      return { type: 'Point', coordinates: [lng, lat] }; // [longitude, latitude]
    }
  } catch (error) {
    console.error('Geocoding error:', error.message);
  }
  return null;
};

// --- CREATE A NEW LISTING ---
router.post('/', auth, async (req, res) => {
  try {
    const { listingType, description, location } = req.body;
    
    let structuredData = {};
    try {
      const aiResponse = await axios.post('http://127.0.0.1:5002/process', { description });
      structuredData = aiResponse.data;
    } catch (aiError) { console.error("AI Service Error:", aiError.message); }

    const geolocation = await geocodeLocation(location);

    const newListing = new Listing({
      listingType,
      description,
      location,
      geolocation,
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

// --- READ ALL LISTINGS ---
router.get('/', async (req, res) => {
  try {
    const listings = await Listing.find().populate('postedBy', ['_id', 'name', 'company']).sort({ createdAt: -1 });
    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- READ USER'S OWN LISTINGS ---
router.get('/mine', auth, async (req, res) => {
  try {
    const listings = await Listing.find({ postedBy: req.user.id }).sort({ createdAt: -1 });
    res.json(listings);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- FIND MATCHES FOR A LISTING ---
router.get('/:id/matches', auth, async (req, res) => {
    try {
      const sourceListing = await Listing.findById(req.params.id);
      if (!sourceListing || !sourceListing.structuredData?.material) {
        return res.status(404).json({ msg: 'Source listing or its material data not found' });
      }
      const targetType = sourceListing.listingType === 'OFFER' ? 'REQUEST' : 'OFFER';
      const potentialMatches = await Listing.find({
        listingType: targetType,
        status: 'open',
        _id: { $ne: sourceListing._id }
      }).populate('postedBy', ['name', 'company']);

      const sourceMaterial = sourceListing.structuredData.material.toLowerCase().trim();
      const matches = potentialMatches.filter(listing => {
        if (!listing.structuredData?.material) return false;
        const targetMaterial = listing.structuredData.material.toLowerCase().trim();
        return sourceMaterial.includes(targetMaterial) || targetMaterial.includes(sourceMaterial);
      });
      res.json(matches);
    } catch (err) {
      console.error(err.message);
      res.status(500).send('Server Error');
    }
});

// --- UPDATE A LISTING ---
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
    } catch (aiError) { console.error("AI Service Error:", aiError.message); }
    
    const geolocation = await geocodeLocation(location);

    const updatedListing = await Listing.findByIdAndUpdate(
      req.params.id,
      { $set: { description, location, structuredData, geolocation } },
      { new: true }
    );
    res.json(updatedListing);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// --- DELETE A LISTING ---
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