const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  addDeliveryPersonnel,
  getDeliveryPersonnel,
  updateDeliveryPersonnel,
  deleteDeliveryPersonnel,
  assignDeliveries,
  getDeliveryRoutes,
  updateDeliveryRoute,
  deleteDeliveryRoute,
  startDeliveryRoute,
  completeDeliveryRoute,
  updateDeliveryProof,
  updateDeliveryStatus,
  getPendingDeliveries
} = require('../controllers/deliveryController');

router.use(protect);

// Personnel routes
router.route('/personnel')
  .get(getDeliveryPersonnel)
  .post(addDeliveryPersonnel);

router.route('/personnel/:id')
  .put(updateDeliveryPersonnel)
  .delete(deleteDeliveryPersonnel);

// Delivery assignment and routes
router.post('/assign', assignDeliveries);

router.route('/routes')
  .get(getDeliveryRoutes);

router.route('/routes/:id')
  .put(updateDeliveryRoute)
  .delete(deleteDeliveryRoute);

router.put('/routes/:id/start', startDeliveryRoute);
router.put('/routes/:id/complete', completeDeliveryRoute);

// Delivery proof and status
router.put('/:saleId/proof', updateDeliveryProof);
router.put('/:saleId/status', updateDeliveryStatus);
router.get('/pending', getPendingDeliveries);

module.exports = router;
