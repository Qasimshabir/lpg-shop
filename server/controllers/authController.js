const { validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const { getSupabaseClient } = require('../config/supabase');
const { generateToken } = require('../middleware/authMiddleware');

// @desc    Register user
// @route   POST /api/register
// @access  Public
const register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const { name, email, password, phone, address, shopName, ownerName, city } = req.body;
    const supabase = getSupabaseClient();

    // Check if user exists by email or phone
    const { data: existingUsers } = await supabase
      .from('users')
      .select('email, phone')
      .or(`email.eq.${email},phone.eq.${phone}`);

    if (existingUsers && existingUsers.length > 0) {
      const field = existingUsers[0].email === email ? 'email' : 'phone number';
      return res.status(400).json({
        success: false,
        message: `User with this ${field} already exists`
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Get default role (staff or customer)
    const { data: defaultRole } = await supabase
      .from('roles')
      .select('id')
      .eq('name', 'staff')
      .single();

    // Create user
    const { data: user, error } = await supabase
      .from('users')
      .insert([
        {
          name,
          email,
          password: hashedPassword,
          phone,
          role_id: defaultRole?.id || null,
          is_active: true
        }
      ])
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to create user',
        error: error.message
      });
    }

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        token: generateToken(user.id)
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate a user
// @route   POST /api/login
// @access  Public
const login = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const { identifier, password } = req.body;
    const supabase = getSupabaseClient();

    // Check if identifier is email or phone
    const isEmail = identifier.includes('@');
    const query = supabase
      .from('users')
      .select('*, roles(name, permissions)')
      .eq(isEmail ? 'email' : 'phone', identifier)
      .single();

    const { data: user, error } = await query;

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.is_active) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login
    await supabase
      .from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', user.id);

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.roles?.name || null,
        lastLogin: new Date().toISOString(),
        token: generateToken(user.id)
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in user
// @route   GET /api/me
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

// @desc    Update user details
// @route   PUT /api/updatedetails
// @access  Private
const updateDetails = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { name, email, phone } = req.body;

    const fieldsToUpdate = {};
    if (name) fieldsToUpdate.name = name;
    if (email) fieldsToUpdate.email = email;
    if (phone) fieldsToUpdate.phone = phone;

    const { data: user, error } = await supabase
      .from('users')
      .update(fieldsToUpdate)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Failed to update user details',
        error: error.message
      });
    }

    res.json({
      success: true,
      message: 'User details updated successfully',
      data: user
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update password
// @route   PUT /api/updatepassword
// @access  Private
const updatePassword = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { currentPassword, newPassword } = req.body;

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
    const isMatch = await bcrypt.compare(currentPassword, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update password
    await supabase
      .from('users')
      .update({ password: hashedPassword })
      .eq('id', req.user.id);

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Forgot password
// @route   POST /api/forgotpassword
// @access  Public
const forgotPassword = async (req, res, next) => {
  try {
    const { identifier } = req.body;
    const supabase = getSupabaseClient();

    const isEmail = identifier.includes('@');
    const { data: user } = await supabase
      .from('users')
      .select('id, email')
      .eq(isEmail ? 'email' : 'phone', identifier)
      .single();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // In production, send email/SMS with reset link
    res.json({
      success: true,
      message: 'Password reset instructions sent to your email/phone'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Reset password
// @route   PUT /api/resetpassword/:resettoken
// @access  Public
const resetPassword = async (req, res, next) => {
  try {
    // Implement token-based password reset logic here
    res.json({
      success: true,
      message: 'Password reset successful'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete profile
// @route   DELETE /api/profile
// @access  Private
const deleteProfile = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { password } = req.body;

    // Get user with password
    const { data: user } = await supabase
      .from('users')
      .select('password')
      .eq('id', req.user.id)
      .single();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password'
      });
    }

    // Soft delete
    await supabase
      .from('users')
      .update({ is_active: false })
      .eq('id', req.user.id);

    res.json({
      success: true,
      message: 'Profile deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Logout user
// @route   POST /api/logout
// @access  Public
const logout = async (req, res, next) => {
  try {
    res.json({
      success: true,
      message: 'User logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getMe,
  updateDetails,
  updatePassword,
  forgotPassword,
  resetPassword,
  deleteProfile,
  logout
};
