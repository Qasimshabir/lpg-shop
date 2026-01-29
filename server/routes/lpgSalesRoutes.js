const express = require('express');
const {
  createLPGSale,
  getLPGSales,
  getSalesReport
} = require('../controllers/lpgSalesController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes are protected
router.use(protect);

// Sales routes
router.route('/')
  .get(getLPGSales)
  .post(createLPGSale);

// Reports
router.get('/report', getSalesReport);

module.exports = router;