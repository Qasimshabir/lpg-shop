const express = require('express');
const {
  getCategories,
  getCategoriesWithStats
} = require('../controllers/categoryController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect); // All routes require authentication

router.route('/').get(getCategories);
router.route('/stats').get(getCategoriesWithStats);

module.exports = router;