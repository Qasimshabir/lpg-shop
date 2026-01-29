const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  addDeliveryPersonnel,
  getDeliveryPersonnel,
  updateDeliveryPersonnel,
  assignDeliveries,
  getDeliveryRoutes,
  startDeliveryRoute,
  completeDeliveryRoute,
  updateDeliveryProof,
  getPendingDeliveries
} = require('../controllers/deliveryController');

router.use(protect);

// Personnel routes
router.route('/personnel')
  .get(getDeliveryPersonnel)
  .post(addDeliveryPersonnel);

router.put('/personnel/:id', updateDeliveryPersonnel);

// Delivery assignment and routes
router.post('/assign', assignDeliveries);
router.get('/routes', getDeliveryRoutes);
router.put('/routes/:id/start', startDeliveryRoute);
router.put('/routes/:id/complete', completeDeliveryRoute);

// Delivery proof and status
router.put('/:saleId/proof', updateDeliveryProof);
router.get('/pending', getPendingDeliveries);

module.exports = router;
