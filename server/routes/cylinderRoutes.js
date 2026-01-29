const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { auditLog } = require('../middleware/auditMiddleware');
const {
  registerCylinder,
  getCylinders,
  getCylinderBySerial,
  updateCylinderStatus,
  recordInspection,
  getCylindersDueInspection,
  getCylindersWithCustomer
} = require('../controllers/cylinderController');

router.use(protect);

router.route('/')
  .get(getCylinders)
  .post(auditLog('create', 'cylinder'), registerCylinder);

router.get('/due-inspection', getCylindersDueInspection);
router.get('/with-customer/:customerId', getCylindersWithCustomer);
router.get('/:serialNumber', getCylinderBySerial);
router.put('/:id/status', auditLog('update', 'cylinder'), updateCylinderStatus);
router.post('/:id/inspection', auditLog('create', 'cylinder'), recordInspection);

module.exports = router;
