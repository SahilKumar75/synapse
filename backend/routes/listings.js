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

    // Fallback: extract material from description if missing
    if (!structuredData.material) {
      const materialMatch = description.match(/material\s*[:\-]?\s*(\w+)/i);
      if (materialMatch && materialMatch[1]) {
        structuredData.material = materialMatch[1];
        console.log(`[DEBUG] Fallback extracted material: ${structuredData.material}`);
      } else {
        // Try to extract last word if it matches a known material
        const knownMaterials = ['wood', 'steel', 'plastic', 'glass', 'copper', 'aluminum', 'sugarcane'];
        const words = description.toLowerCase().split(/\s+/);
        const lastWord = words[words.length - 1].replace(/[^a-z]/g, '');
        if (knownMaterials.includes(lastWord)) {
          structuredData.material = lastWord;
          console.log(`[DEBUG] Fallback extracted material from last word: ${structuredData.material}`);
        } else {
          console.log('[DEBUG] No material found in description for fallback.');
        }
      }
    }

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
    // Debug print: log geolocation for each listing
    listings.forEach(listing => {
      console.log(`[DEBUG] Listing: id=${listing._id}, location=${listing.location}, geolocation=${JSON.stringify(listing.geolocation)}`);
    });
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
        console.log('[DEBUG] Source listing missing or no material:', sourceListing);
        return res.status(404).json({ msg: 'Source listing or its material data not found' });
      }
      const targetType = sourceListing.listingType === 'OFFER' ? 'REQUEST' : 'OFFER';
      const potentialMatches = await Listing.find({
        listingType: targetType,
        status: 'open',
        _id: { $ne: sourceListing._id }
      }).populate('postedBy', ['name', 'company']);

      console.log(`[DEBUG] Found ${potentialMatches.length} potential matches for type ${targetType}`);
      const sourceMaterial = sourceListing.structuredData.material.toLowerCase().trim();
      console.log(`[DEBUG] Source material: '${sourceMaterial}'`);
      const matches = potentialMatches.filter(listing => {
        if (!listing.structuredData?.material) {
          console.log(`[DEBUG] Skipping listing ${listing._id}: no material`);
          return false;
        }
        const targetMaterial = listing.structuredData.material.toLowerCase().trim();
        const isMatch = sourceMaterial.includes(targetMaterial) || targetMaterial.includes(sourceMaterial);
        console.log(`[DEBUG] Comparing source '${sourceMaterial}' with target '${targetMaterial}' => ${isMatch}`);
        return isMatch;
      });
      console.log(`[DEBUG] Final matches found: ${matches.length}`);
      res.json(matches);
    } catch (err) {
      console.error('[ERROR] /:id/matches:', err.message);
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