const express = require('express');
const {
  getMe,
  updateMe,
  changePassword
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect); // All routes require authentication

router.route('/me')
  .get(getMe)
  .put(updateMe);

router.put('/password', changePassword);

module.exports = router;
