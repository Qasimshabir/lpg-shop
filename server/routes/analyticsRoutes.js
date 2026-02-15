const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getBusinessInsights,
  getRevenueForecast,
  getCustomerLifetimeValue,
} = require('../controllers/analyticsController');

router.use(protect);

router.get('/insights', getBusinessInsights);
router.get('/forecast', getRevenueForecast);
router.get('/customer-lifetime-value', getCustomerLifetimeValue);

module.exports = router;
