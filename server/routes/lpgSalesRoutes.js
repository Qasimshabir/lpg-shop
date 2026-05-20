const express = require('express');
const {
  createLPGSale,
  getLPGSales,
  getSalesReport,
  deleteLPGSale
} = require('../controllers/lpgSalesController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes are protected
router.use(protect);

// Specific routes MUST come before parameterized routes
router.get('/report', getSalesReport);

// Sales routes
router.route('/')
  .get(getLPGSales)
  .post(createLPGSale);

// Delete sale route
router.route('/:id')
  .delete(deleteLPGSale);

module.exports = router;