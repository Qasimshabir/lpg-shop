const { getSupabaseClient } = require('../config/supabase');
const bcrypt = require('bcryptjs');

// @desc    Get current user profile
// @route   GET /api/users/me
// @access  Private
const getMe = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: user, error } = await supabase
      .from('users')
      .select('id, name, email, phone, is_active, created_at, roles(name, permissions)')
      .eq('id', req.user.id)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update user profile
// @route   PUT /api/users/me
// @access  Private
const updateMe = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const fieldsToUpdate = {};
    if (req.body.name) fieldsToUpdate.name = req.body.name;
    if (req.body.phone) fieldsToUpdate.phone = req.body.phone;

    const { data: user, error } = await supabase
      .from('users')
      .update(fieldsToUpdate)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to update profile',
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: user
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Change password
// @route   PUT /api/users/password
// @access  Private
const changePassword = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Get user with password
    const { data: user, error } = await supabase
      .from('users')
      .select('id, password')
      .eq('id', req.user.id)
      .single();

    if (error || !user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check current password
    const isMatch = await bcrypt.compare(req.body.currentPassword, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(req.body.newPassword, salt);

    // Update password
    await supabase
      .from('users')
      .update({ password: hashedPassword })
      .eq('id', req.user.id);

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMe,
  updateMe,
  changePassword
};
