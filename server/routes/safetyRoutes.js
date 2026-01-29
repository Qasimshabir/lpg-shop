const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  getChecklistForSale,
  createChecklist,
  checkItem,
  addAcknowledgment,
  reportIncident,
  getIncidents,
  updateIncidentStatus,
  getComplianceReport
} = require('../controllers/safetyController');

router.use(protect);

// Checklist routes
router.post('/checklists', createChecklist);
router.get('/checklists/sale/:saleId', getChecklistForSale);
router.put('/checklists/:id/items/:itemId', checkItem);
router.post('/checklists/:id/acknowledge', addAcknowledgment);

// Incident routes
router.route('/incidents')
  .get(getIncidents)
  .post(reportIncident);

router.put('/incidents/:id/status', updateIncidentStatus);

// Compliance report
router.get('/compliance-report', getComplianceReport);

module.exports = router;
