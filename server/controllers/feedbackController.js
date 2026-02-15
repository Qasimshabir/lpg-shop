const { getSupabaseClient } = require('../config/supabase');

// @desc    Submit new feedback
// @route   POST /api/feedback
// @access  Private
const submitFeedback = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const feedbackData = {
      user_id: req.user.id,
      category: req.body.category || 'general',
      subject: req.body.subject || req.body.title,
      message: req.body.message,
      rating: req.body.rating || null,
      status: 'pending'
    };

    const { data: feedback, error } = await supabase
      .from('feedback')
      .insert([feedbackData])
      .select()
      .single();

    if (error) throw error;

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
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('feedback')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id);

    if (req.query.status) {
      query = query.eq('status', req.query.status);
    }

    if (req.query.category) {
      query = query.eq('category', req.query.category);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data: feedbacks, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: feedbacks?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: feedbacks || []
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
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('feedback')
      .select('*, users(name, email)', { count: 'exact' });

    if (req.query.status) {
      query = query.eq('status', req.query.status);
    }

    if (req.query.category) {
      query = query.eq('category', req.query.category);
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data: feedbacks, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: feedbacks?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: feedbacks || []
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
    const supabase = getSupabaseClient();
    const { status, adminResponse } = req.body;

    const updateData = { status };
    if (adminResponse) {
      updateData.response = adminResponse;
      updateData.responded_at = new Date().toISOString();
    }

    const { data: feedback, error } = await supabase
      .from('feedback')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!feedback) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

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
    const supabase = getSupabaseClient();
    
    // Get status stats
    const { data: statusStats, error: statusError } = await supabase
      .from('feedback')
      .select('status')
      .then(result => {
        if (result.error) throw result.error;
        const stats = {};
        result.data.forEach(item => {
          stats[item.status] = (stats[item.status] || 0) + 1;
        });
        return { data: Object.entries(stats).map(([status, count]) => ({ _id: status, count })), error: null };
      });

    if (statusError) throw statusError;

    // Get category stats
    const { data: categoryStats, error: categoryError } = await supabase
      .from('feedback')
      .select('category')
      .then(result => {
        if (result.error) throw result.error;
        const stats = {};
        result.data.forEach(item => {
          stats[item.category] = (stats[item.category] || 0) + 1;
        });
        return { data: Object.entries(stats).map(([category, count]) => ({ _id: category, count })), error: null };
      });

    if (categoryError) throw categoryError;

    res.json({
      success: true,
      data: {
        statusStats: statusStats || [],
        categoryStats: categoryStats || []
      }
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
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('feedback')
      .select('*, users(name, email)')
      .eq('id', req.params.id);

    // If not admin, only allow viewing own feedback
    if (req.user.role !== 'admin') {
      query = query.eq('user_id', req.user.id);
    }

    const { data: feedback, error } = await query.single();

    if (error || !feedback) {
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
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('feedback')
      .delete()
      .eq('id', req.params.id);

    // If not admin, only allow deleting own feedback
    if (req.user.role !== 'admin') {
      query = query.eq('user_id', req.user.id);
    }

    const { data, error } = await query.select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Feedback not found'
      });
    }

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
