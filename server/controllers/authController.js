const { validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken } = require('../middleware/authMiddleware');

// @desc    Register user
// @route   POST /api/register
// @access  Public
const register = async (req, res, next) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const { name, email, password, phone, address, shopName, ownerName, city } = req.body;

    // Check if user exists by email or phone
    const userExists = await User.findOne({
      $or: [{ email }, { phone }]
    });
    if (userExists) {
      const field = userExists.email === email ? 'email' : 'phone number';
      return res.status(400).json({
        success: false,
        message: `User with this ${field} already exists`
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      password,
      phone,
      address,
      shopName,
      ownerName,
      city
    });

    if (user) {
      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          _id: user._id,
          name: user.name,
          email: user.email,
          shopName: user.shopName,
          ownerName: user.ownerName,
          phone: user.phone,
          address: user.address,
          city: user.city,
          token: generateToken(user._id)
        }
      });
    } else {
      res.status(400).json({
        success: false,
        message: 'Invalid user data'
      });
    }
  } catch (error) {
    next(error);
  }
};

// @desc    Authenticate a user
// @route   POST /api/login
// @access  Public
const login = async (req, res, next) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: errors.array()
      });
    }

    const { identifier, password } = req.body; // identifier can be email or phone

    // Check for user by email or phone and include password
    const user = await User.findByEmailOrPhone(identifier);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        shopName: user.shopName,
        ownerName: user.ownerName,
        phone: user.phone,
        address: user.address,
        city: user.city,
        avatar: user.avatar,
        role: user.role,
        lastLogin: new Date(),
        token: generateToken(user._id)
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
    const user = await User.findById(req.user.id);

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
    const fieldsToUpdate = {
      name: req.body.name,
      email: req.body.email,
      shopName: req.body.shopName,
      ownerName: req.body.ownerName,
      phone: req.body.phone,
      address: req.body.address,
      city: req.body.city,
      avatar: req.body.avatar
    };

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
      new: true,
      runValidators: true
    });

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
    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    if (!(await user.matchPassword(req.body.currentPassword))) {
      return res.status(401).json({
        success: false,
        message: 'Password is incorrect'
      });
    }

    user.password = req.body.newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password updated successfully',
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        shopName: user.shopName,
        ownerName: user.ownerName,
        token: generateToken(user._id)
      }
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
    const { identifier } = req.body; // email or phone
    
    const user = await User.findByEmailOrPhone(identifier);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Generate reset token
    const resetToken = user.generatePasswordResetToken();
    await user.save();
    
    // In a real app, you would send this via email/SMS
    // For now, we'll return it in the response (not recommended for production)
    res.json({
      success: true,
      message: 'Password reset token generated. Check your email/SMS.',
      resetToken // Remove this in production
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
    const crypto = require('crypto');
    
    // Get hashed token
    const resetPasswordToken = crypto
      .createHash('sha256')
      .update(req.params.resettoken)
      .digest('hex');
      
    const user = await User.findOne({
      passwordResetToken: resetPasswordToken,
      passwordResetExpires: { $gt: Date.now() }
    });
    
    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }
    
    // Set new password
    user.password = req.body.password;
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;
    await user.save();
    
    res.json({
      success: true,
      message: 'Password reset successful',
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        token: generateToken(user._id)
      }
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
    const { password } = req.body;
    
    const user = await User.findById(req.user.id).select('+password');
    
    // Verify password before deletion
    const isMatch = await user.matchPassword(password);
    
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password'
      });
    }
    
    // Soft delete by setting isActive to false
    user.isActive = false;
    await user.save();
    
    res.json({
      success: true,
      message: 'Profile deleted successfully'
    });
    
  } catch (error) {
    next(error);
  }
};

// @desc    Logout user / clear cookie
// @route   POST /api/logout
// @access  Private
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
