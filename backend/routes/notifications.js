const express = require('express');
const Notification = require('../models/Notification');
const User = require('../models/User');
const jwt = require('jsonwebtoken');

const router = express.Router();

// @route   POST api/notifications
// @desc    Send a notification to a user
// @access  Private
router.post('/', async (req, res) => {
  const token = req.header('x-auth-token');
  if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const senderId = decoded.user.id;
    const { receiverId, message } = req.body;
    if (!receiverId || !message) {
      return res.status(400).json({ msg: 'Receiver and message required' });
    }
    // Check receiver exists
    const receiver = await User.findById(receiverId);
    if (!receiver) return res.status(404).json({ msg: 'Receiver not found' });
    // Create notification
    const notification = new Notification({
      sender: senderId,
      receiver: receiverId,
      message,
    });
    await notification.save();
    res.status(201).json({ msg: 'Notification sent', notification });
  } catch (err) {
    res.status(401).json({ msg: 'Token is not valid' });
  }
});

// @route   GET api/notifications
// @desc    Get notifications for current user
// @access  Private
router.get('/', async (req, res) => {
  const token = req.header('x-auth-token');
  if (!token) return res.status(401).json({ msg: 'No token, authorization denied' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.user.id;
    const notifications = await Notification.find({ receiver: userId })
      .populate('sender', 'name email company')
      .sort({ createdAt: -1 });
    res.json(notifications);
  } catch (err) {
    res.status(401).json({ msg: 'Token is not valid' });
  }
});

module.exports = router;
