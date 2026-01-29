const express = require('express');
const {
  submitFeedback,
  getMyFeedbacks,
  getAllFeedbacks,
  updateFeedbackStatus,
  getFeedbackStats,
  getFeedback,
  deleteFeedback
} = require('../controllers/feedbackController');

const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// User routes
router.post('/', protect, submitFeedback);
router.get('/my', protect, getMyFeedbacks);
router.get('/:id', protect, getFeedback);
router.delete('/:id', protect, deleteFeedback);

// Admin routes (Note: Add admin middleware when you implement role-based access)
router.get('/admin/all', protect, getAllFeedbacks);
router.get('/admin/stats', protect, getFeedbackStats);
router.put('/:id/status', protect, updateFeedbackStatus);

module.exports = router;
