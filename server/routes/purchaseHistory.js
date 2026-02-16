const express = require('express');
const router = express.Router();
const {
  getCustomerPurchaseHistory,
  getCustomerPurchaseSummary,
  getSaleDetails,
  getCustomerProductPreferences,
  getPurchaseHistoryByDateRange,
  getCustomerLifetimeValue,
  getCustomerLoyaltyMetrics,
  getMonthlyPurchaseTrends,
  searchPurchaseHistory,
  exportPurchaseHistory
} = require('../controllers/purchaseHistoryController');

const { protect } = require('../middleware/authMiddleware');

// All routes require authentication
router.use(protect);

/**
 * @route   GET /api/purchase-history/:customerId
 * @desc    Get complete purchase history for a customer
 * @access  Private
 * @query   limit, offset, startDate, endDate
 */
router.get('/:customerId', getCustomerPurchaseHistory);

/**
 * @route   GET /api/purchase-history/:customerId/summary
 * @desc    Get purchase summary for a customer
 * @access  Private
 */
router.get('/:customerId/summary', getCustomerPurchaseSummary);

/**
 * @route   GET /api/purchase-history/:customerId/lifetime-value
 * @desc    Calculate customer lifetime value
 * @access  Private
 */
router.get('/:customerId/lifetime-value', getCustomerLifetimeValue);

/**
 * @route   GET /api/purchase-history/:customerId/loyalty
 * @desc    Get customer loyalty metrics
 * @access  Private
 */
router.get('/:customerId/loyalty', getCustomerLoyaltyMetrics);

/**
 * @route   GET /api/purchase-history/:customerId/preferences
 * @desc    Get customer's product preferences
 * @access  Private
 * @query   limit
 */
router.get('/:customerId/preferences', getCustomerProductPreferences);

/**
 * @route   GET /api/purchase-history/:customerId/trends
 * @desc    Get monthly purchase trends
 * @access  Private
 * @query   months
 */
router.get('/:customerId/trends', getMonthlyPurchaseTrends);

/**
 * @route   GET /api/purchase-history/:customerId/date-range
 * @desc    Get purchase history by date range
 * @access  Private
 * @query   startDate, endDate (required)
 */
router.get('/:customerId/date-range', getPurchaseHistoryByDateRange);

/**
 * @route   GET /api/purchase-history/:customerId/search
 * @desc    Search purchase history
 * @access  Private
 * @query   query, limit
 */
router.get('/:customerId/search', searchPurchaseHistory);

/**
 * @route   GET /api/purchase-history/:customerId/export
 * @desc    Export purchase history to CSV
 * @access  Private
 * @query   startDate, endDate
 */
router.get('/:customerId/export', exportPurchaseHistory);

/**
 * @route   GET /api/purchase-history/sale/:saleId
 * @desc    Get detailed information for a specific sale
 * @access  Private
 */
router.get('/sale/:saleId', getSaleDetails);

module.exports = router;
