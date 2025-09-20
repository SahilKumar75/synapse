// backend/routes/places.js
const express = require('express');
const axios = require('axios');
const router = express.Router();

const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY || 'AIzaSyDSKfX62OR56G4BZnAVtr_FzcvoIwA9IZI';

// Autocomplete endpoint
router.get('/autocomplete', async (req, res) => {
  const input = req.query.input;
  if (!input) return res.status(400).json({ error: 'Missing input' });
  try {
    const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${GOOGLE_API_KEY}&components=country:in`;
    const response = await axios.get(url);
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch autocomplete', details: err.message });
  }
});

// Place details endpoint
router.get('/details', async (req, res) => {
  const placeId = req.query.placeId;
  if (!placeId) return res.status(400).json({ error: 'Missing placeId' });
  try {
    const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(placeId)}&key=${GOOGLE_API_KEY}`;
    const response = await axios.get(url);
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch details', details: err.message });
  }
});

module.exports = router;
