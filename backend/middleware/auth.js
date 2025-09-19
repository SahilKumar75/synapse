// backend/middleware/auth.js

const jwt = require('jsonwebtoken');

module.exports = function (req, res, next) {
  // 1. Get token from the header
  const token = req.header('x-auth-token');

  // 2. Check if no token is present
  if (!token) {
    return res.status(401).json({ msg: 'No token, authorization denied' });
  }

  // 3. Verify the token
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 4. Attach user from the payload to the request object
    req.user = decoded.user;
    next(); // Move on to the next piece of middleware/route handler
  } catch (err) {
    res.status(401).json({ msg: 'Token is not valid' });
  }
};