const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name'],
    trim: true,
    maxlength: [50, 'Name cannot be more than 50 characters']
  },
  shopName: {
    type: String,
    required: [true, 'Please add a shop name'],
    trim: true,
    maxlength: [100, 'Shop name cannot be more than 100 characters']
  },
  ownerName: {
    type: String,
    required: [true, 'Please add owner name'],
    trim: true,
    maxlength: [100, 'Owner name cannot be more than 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    lowercase: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false
  },

  phone: {
    type: String,
    required: [true, 'Please add a phone number'],
    unique: true,
    trim: true,
    match: [
      /^[+]?[1-9]?[0-9]{10,14}$/,
      'Please add a valid phone number'
    ]
  },
  address: {
    type: String,
    required: [true, 'Please add shop address'],
    trim: true,
    maxlength: [200, 'Address cannot be more than 200 characters']
  },
  city: {
    type: String,
    required: [true, 'Please add city'],
    trim: true,
    maxlength: [50, 'City cannot be more than 50 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  avatar: {
    type: String, // URL or base64 string
    default: null
  },
  passwordResetToken: {
    type: String,
    default: null
  },
  passwordResetExpires: {
    type: Date,
    default: null
  },
  lastLogin: {
    type: Date,
    default: null
  },
  role: {
    type: String,
    enum: ['super-admin', 'admin', 'manager', 'sales-person', 'delivery-person', 'inventory-manager', 'owner', 'employee'],
    default: 'owner'
  },
  roleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Role'
  },
  permissions: [{
    resource: String,
    actions: [String]
  }]
}, {
  timestamps: true
});

// Encrypt password using bcrypt
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Generate password reset token
userSchema.methods.generatePasswordResetToken = function() {
  const crypto = require('crypto');
  const resetToken = crypto.randomBytes(20).toString('hex');
  
  this.passwordResetToken = crypto
    .createHash('sha256')
    .update(resetToken)
    .digest('hex');
    
  this.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  
  return resetToken;
};

// Check if user can login (alternative login with phone)
userSchema.statics.findByEmailOrPhone = async function(identifier) {
  return await this.findOne({
    $or: [
      { email: identifier.toLowerCase() },
      { phone: identifier }
    ],
    isActive: true
  }).select('+password');
};

// Static method to get user stats
userSchema.statics.getUserStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: '$city',
        count: { $sum: 1 }
      }
    }
  ]);
  return stats;
};

module.exports = mongoose.model('User', userSchema);
