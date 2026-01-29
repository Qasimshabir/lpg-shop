const express = require('express');
const {
  getLPGCustomers,
  getLPGCustomer,
  createLPGCustomer,
  updateLPGCustomer,
  deleteLPGCustomer,
  addPremises,
  updatePremises,
  removePremises,
  addRefillRecord,
  getRefillHistory,
  updateCredit,
  getCustomersDueForRefill,
  getTopCustomers,
  getCustomerAnalytics,
  getConsumptionPattern
} = require('../controllers/lpgCustomerController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes are protected
router.use(protect);

// Specific routes MUST come before parameterized routes
router.get('/due-refill', getCustomersDueForRefill);
router.get('/top-customers', getTopCustomers);
router.get('/analytics', getCustomerAnalytics);

// Customer CRUD routes
router.route('/')
  .get(getLPGCustomers)
  .post(createLPGCustomer);

router.route('/:id')
  .get(getLPGCustomer)
  .put(updateLPGCustomer)
  .delete(deleteLPGCustomer);

// Premises management
router.post('/:id/premises', addPremises);
router.put('/:id/premises/:premisesId', updatePremises);
router.delete('/:id/premises/:premisesId', removePremises);

// Refill management
router.post('/:id/refill', addRefillRecord);
router.get('/:id/refill-history', getRefillHistory);

// Credit management
router.put('/:id/credit', updateCredit);

// Customer-specific analytics
router.get('/:id/consumption-pattern', getConsumptionPattern);

module.exports = router;