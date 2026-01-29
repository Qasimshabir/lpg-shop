const express = require('express');
const { body } = require('express-validator');
const {
  register,
  login,
  getMe,
  updateDetails,
  updatePassword,
  forgotPassword,
  resetPassword,
  deleteProfile,
  logout
} = require('../controllers/authController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Validation rules
const registerValidation = [
  body('name').trim().isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').isEmail().withMessage('Please include a valid email'),
  body('phone').matches(/^[+]?[1-9]?[0-9]{10,14}$/).withMessage('Please include a valid phone number'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('shopName').trim().isLength({ min: 2 }).withMessage('Shop name must be at least 2 characters'),
  body('ownerName').trim().isLength({ min: 2 }).withMessage('Owner name must be at least 2 characters'),
  body('address').trim().isLength({ min: 5 }).withMessage('Address must be at least 5 characters'),
  body('city').trim().isLength({ min: 2 }).withMessage('City must be at least 2 characters')
];

const loginValidation = [
  body('identifier').exists().withMessage('Email or phone number is required'),
  body('password').exists().withMessage('Password is required')
];

const forgotPasswordValidation = [
  body('identifier').exists().withMessage('Email or phone number is required')
];

const resetPasswordValidation = [
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
];

// Routes
router.post('/register', registerValidation, register);
router.post('/login', loginValidation, login);
router.post('/forgotpassword', forgotPasswordValidation, forgotPassword);
router.put('/resetpassword/:resettoken', resetPasswordValidation, resetPassword);
router.post('/logout', logout);
router.get('/me', protect, getMe);
router.put('/updatedetails', protect, updateDetails);
router.put('/updatepassword', protect, updatePassword);
router.delete('/profile', protect, deleteProfile);

module.exports = router;
