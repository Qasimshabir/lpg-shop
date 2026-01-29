const Feedback = require('../models/Feedback');

// @desc    Submit new feedback
// @route   POST /api/feedback
// @access  Private
const submitFeedback = async (req, res, next) => {
  try {
    const feedbackData = {
      ...req.body,
      userId: req.user.id
    };

    const feedback = await Feedback.create(feedbackData);

    res.status(201).json({
      success: true,
      message: 'Feedback submitted successfully',
      data: feedback
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's feedbacks
// @route   GET /api/feedback/my
// @access  Private
const getMyFeedbacks = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    let query = { userId: req.user.id };

    if (req.query.status) {
      query.status = req.query.status;
    }

    if (req.query.category) {
      query.category = req.query.category;
    }

    const feedbacks = await Feedback.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Feedback.countDocuments(query);

    res.json({
      success: true,
      count: feedbacks.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: feedbacks
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all feedbacks (Admin only)
// @route   GET /api/feedback/admin
// @access  Private/Admin
const getAllFeedbacks = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    let query = {};

    if (req.query.status) {
      query.status = req.query.status;
    }

    if (req.query.category) {
      query.category = req.query.category;
    }

    if (req.query.priority) {
      query.priority = req.query.priority;
    }

    const feedbacks = await Feedback.find(query)
      .populate('userId', 'name email shopName city')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Feedback.countDocuments(query);

    res.json({
      success: true,
      count: feedbacks.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: feedbacks
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update feedback status (Admin only)
// @route   PUT /api/feedback/:id/status
// @access  Private/Admin
const updateFeedbackStatus = async (req, res, next) => {
  try {
    const { status, adminResponse } = req.body;

    const feedback = await Feedback.findById(req.params.id);

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    await feedback.updateStatus(status, adminResponse);

    res.json({
      success: true,
      message: 'Feedback status updated successfully',
      data: feedback
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get feedback statistics (Admin only)
// @route   GET /api/feedback/stats
// @access  Private/Admin
const getFeedbackStats = async (req, res, next) => {
  try {
    const stats = await Feedback.getFeedbackStats();

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single feedback
// @route   GET /api/feedback/:id
// @access  Private
const getFeedback = async (req, res, next) => {
  try {
    let query = { _id: req.params.id };

    // If not admin, only allow viewing own feedback
    if (req.user.role !== 'admin') {
      query.userId = req.user.id;
    }

    const feedback = await Feedback.findOne(query)
      .populate('userId', 'name email shopName');

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    res.json({
      success: true,
      data: feedback
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete feedback
// @route   DELETE /api/feedback/:id
// @access  Private
const deleteFeedback = async (req, res, next) => {
  try {
    let query = { _id: req.params.id };

    // If not admin, only allow deleting own feedback
    if (req.user.role !== 'admin') {
      query.userId = req.user.id;
    }

    const feedback = await Feedback.findOne(query);

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

    await feedback.deleteOne();

    res.json({
      success: true,
      message: 'Feedback deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  submitFeedback,
  getMyFeedbacks,
  getAllFeedbacks,
  updateFeedbackStatus,
  getFeedbackStats,
  getFeedback,
  deleteFeedback
};
