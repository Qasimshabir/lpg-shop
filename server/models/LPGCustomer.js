const mongoose = require('mongoose');

const premisesSchema = new mongoose.Schema({
  _id: {
    type: mongoose.Schema.Types.ObjectId,
    default: () => new mongoose.Types.ObjectId()
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: [100, 'Premises name cannot be more than 100 characters']
  },
  type: {
    type: String,
    required: true,
    enum: ['Residential', 'Commercial', 'Industrial', 'Restaurant', 'Hotel', 'Other'],
    default: 'Residential'
  },
  address: {
    street: {
      type: String,
      required: true,
      trim: true,
      maxlength: [200, 'Street address cannot be more than 200 characters']
    },
    city: {
      type: String,
      required: true,
      trim: true,
      maxlength: [50, 'City cannot be more than 50 characters']
    },
    state: {
      type: String,
      required: true,
      trim: true,
      maxlength: [50, 'State cannot be more than 50 characters']
    },
    pincode: {
      type: String,
      required: true,
      trim: true,
      match: [/^\d{6}$/, 'Please provide a valid 6-digit pincode']
    },
    landmark: {
      type: String,
      trim: true,
      maxlength: [100, 'Landmark cannot be more than 100 characters']
    }
  },
  connectionType: {
    type: String,
    enum: ['Direct', 'Distributor', 'Bulk'],
    default: 'Direct'
  },
  cylinderCapacity: {
    type: String,
    enum: ['11.8kg', '15kg', '45.4kg', 'Mixed'],
    default: '11.8kg'
  },
  estimatedMonthlyConsumption: {
    type: Number, // in kg
    default: 0,
    min: [0, 'Consumption cannot be negative']
  },
  deliveryInstructions: {
    type: String,
    trim: true,
    maxlength: [300, 'Delivery instructions cannot be more than 300 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  isPrimary: {
    type: Boolean,
    default: false
  }
});

const cylinderRefillHistorySchema = new mongoose.Schema({
  _id: {
    type: mongoose.Schema.Types.ObjectId,
    default: () => new mongoose.Types.ObjectId()
  },
  premises: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  cylinderType: {
    type: String,
    required: true,
    enum: ['11.8kg', '15kg', '45.4kg']
  },
  cylinderSerialNumber: {
    type: String,
    trim: true,
    uppercase: true
  },
  refillDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  quantity: {
    type: Number,
    required: true,
    min: [1, 'Quantity must be at least 1']
  },
  pricePerUnit: {
    type: Number,
    required: true,
    min: [0, 'Price cannot be negative']
  },
  totalAmount: {
    type: Number,
    required: true,
    min: [0, 'Total amount cannot be negative']
  },
  depositAmount: {
    type: Number,
    default: 0,
    min: [0, 'Deposit amount cannot be negative']
  },
  refundAmount: {
    type: Number,
    default: 0,
    min: [0, 'Refund amount cannot be negative']
  },
  paymentMethod: {
    type: String,
    enum: ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Credit'],
    default: 'Cash'
  },
  deliveryAddress: {
    type: String,
    trim: true
  },
  deliveryStatus: {
    type: String,
    enum: ['Pending', 'In Transit', 'Delivered', 'Failed'],
    default: 'Pending'
  },
  deliveryDate: {
    type: Date
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [300, 'Notes cannot be more than 300 characters']
  },
  soldBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
});

const lpgCustomerSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  name: {
    type: String,
    required: [true, 'Please add a customer name'],
    trim: true,
    maxlength: [100, 'Customer name cannot be more than 100 characters']
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  phone: {
    type: String,
    required: [true, 'Please add a phone number'],
    trim: true,
    match: [/^[+]?[1-9]?[0-9]{10,14}$/, 'Please add a valid phone number']
  },
  alternatePhone: {
    type: String,
    trim: true,
    match: [/^[+]?[1-9]?[0-9]{10,14}$/, 'Please add a valid alternate phone number']
  },
  // Customer identification
  customerType: {
    type: String,
    enum: ['Individual', 'Business', 'Institution'],
    default: 'Individual'
  },
  businessName: {
    type: String,
    trim: true,
    maxlength: [100, 'Business name cannot be more than 100 characters']
  },
  gstNumber: {
    type: String,
    trim: true,
    uppercase: true,
    match: [/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, 'Please provide a valid GST number']
  },
  // Premises information (replaces vehicles)
  premises: [premisesSchema],
  // Refill history (replaces oil change history)
  refillHistory: [cylinderRefillHistorySchema],
  // Loyalty and spending
  loyaltyPoints: {
    type: Number,
    default: 0,
    min: [0, 'Loyalty points cannot be negative']
  },
  loyaltyTier: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum'],
    default: 'Bronze'
  },
  totalSpent: {
    type: Number,
    default: 0,
    min: [0, 'Total spent cannot be negative']
  },
  totalRefills: {
    type: Number,
    default: 0,
    min: [0, 'Total refills cannot be negative']
  },
  // Credit management
  creditLimit: {
    type: Number,
    default: 0,
    min: [0, 'Credit limit cannot be negative']
  },
  currentCredit: {
    type: Number,
    default: 0,
    min: [0, 'Current credit cannot be negative']
  },
  // Delivery preferences
  preferredDeliveryTime: {
    type: String,
    enum: ['Morning', 'Afternoon', 'Evening', 'Anytime'],
    default: 'Anytime'
  },
  deliveryInstructions: {
    type: String,
    trim: true,
    maxlength: [300, 'Delivery instructions cannot be more than 300 characters']
  },
  // Safety and compliance
  safetyTrainingCompleted: {
    type: Boolean,
    default: false
  },
  safetyTrainingDate: {
    type: Date
  },
  emergencyContact: {
    name: {
      type: String,
      trim: true,
      maxlength: [100, 'Emergency contact name cannot be more than 100 characters']
    },
    phone: {
      type: String,
      trim: true,
      match: [/^[+]?[1-9]?[0-9]{10,14}$/, 'Please add a valid emergency contact phone']
    },
    relationship: {
      type: String,
      trim: true,
      maxlength: [50, 'Relationship cannot be more than 50 characters']
    }
  },
  // General fields
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot be more than 500 characters']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  tags: [{
    type: String,
    trim: true
  }]
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
lpgCustomerSchema.index({ userId: 1, name: 1 });
lpgCustomerSchema.index({ userId: 1, phone: 1 });
lpgCustomerSchema.index({ userId: 1, email: 1 });
lpgCustomerSchema.index({ userId: 1, customerType: 1 });
lpgCustomerSchema.index({ userId: 1, loyaltyTier: 1 });
lpgCustomerSchema.index({ name: 'text', businessName: 'text', phone: 'text' });

// Virtual for loyalty status calculation
lpgCustomerSchema.virtual('loyaltyStatus').get(function() {
  if (this.loyaltyPoints >= 2000) return 'Platinum';
  if (this.loyaltyPoints >= 1000) return 'Gold';
  if (this.loyaltyPoints >= 500) return 'Silver';
  return 'Bronze';
});

// Virtual for available credit
lpgCustomerSchema.virtual('availableCredit').get(function() {
  return Math.max(0, this.creditLimit - this.currentCredit);
});

// Virtual for primary premises
lpgCustomerSchema.virtual('primaryPremises').get(function() {
  return this.premises.find(p => p.isPrimary) || this.premises[0];
});

// Virtual for average monthly consumption
lpgCustomerSchema.virtual('averageMonthlyConsumption').get(function() {
  if (this.refillHistory.length === 0) return 0;
  
  const totalConsumption = this.refillHistory.reduce((sum, refill) => {
    const cylinderWeight = parseFloat(refill.cylinderType.replace('kg', ''));
    return sum + (cylinderWeight * refill.quantity);
  }, 0);
  
  const monthsActive = Math.max(1, Math.ceil((Date.now() - this.createdAt) / (1000 * 60 * 60 * 24 * 30)));
  return (totalConsumption / monthsActive).toFixed(2);
});

// Virtual for last refill date
lpgCustomerSchema.virtual('lastRefillDate').get(function() {
  if (this.refillHistory.length === 0) return null;
  return this.refillHistory.sort((a, b) => b.refillDate - a.refillDate)[0].refillDate;
});

// Virtual for next expected refill (based on average consumption)
lpgCustomerSchema.virtual('nextExpectedRefill').get(function() {
  const lastRefill = this.lastRefillDate;
  if (!lastRefill) return null;
  
  const avgConsumption = parseFloat(this.averageMonthlyConsumption);
  if (avgConsumption === 0) return null;
  
  const daysToNextRefill = Math.ceil(30 / (avgConsumption / 14.2)); // Assuming 14.2kg average
  const nextRefillDate = new Date(lastRefill);
  nextRefillDate.setDate(nextRefillDate.getDate() + daysToNextRefill);
  
  return nextRefillDate;
});

// Method to add premises
lpgCustomerSchema.methods.addPremises = function(premisesData) {
  // If this is the first premises, make it primary
  if (this.premises.length === 0) {
    premisesData.isPrimary = true;
  }
  
  this.premises.push(premisesData);
  return this.save();
};

// Method to update premises
lpgCustomerSchema.methods.updatePremises = function(premisesId, updateData) {
  const premises = this.premises.id(premisesId);
  if (!premises) {
    throw new Error('Premises not found');
  }
  
  Object.assign(premises, updateData);
  return this.save();
};

// Method to remove premises
lpgCustomerSchema.methods.removePremises = function(premisesId) {
  const premises = this.premises.id(premisesId);
  if (!premises) {
    throw new Error('Premises not found');
  }
  
  // Don't allow removal if it's the only premises
  if (this.premises.length === 1) {
    throw new Error('Cannot remove the only premises');
  }
  
  // If removing primary premises, make another one primary
  if (premises.isPrimary && this.premises.length > 1) {
    const otherPremises = this.premises.find(p => p._id.toString() !== premisesId);
    if (otherPremises) {
      otherPremises.isPrimary = true;
    }
  }
  
  premises.remove();
  return this.save();
};

// Method to add refill record
lpgCustomerSchema.methods.addRefillRecord = function(refillData) {
  // Calculate loyalty points (1 point per 10 rupees spent)
  const pointsEarned = Math.floor(refillData.totalAmount / 10);
  this.loyaltyPoints += pointsEarned;
  this.totalSpent += refillData.totalAmount;
  this.totalRefills += refillData.quantity;
  
  // Update loyalty tier
  this.loyaltyTier = this.loyaltyStatus;
  
  // Add refill record
  this.refillHistory.push(refillData);
  
  return this.save();
};

// Method to update credit
lpgCustomerSchema.methods.updateCredit = function(amount, operation = 'add') {
  if (operation === 'add') {
    this.currentCredit += amount;
  } else if (operation === 'subtract') {
    this.currentCredit = Math.max(0, this.currentCredit - amount);
  }
  
  return this.save();
};

// Static method to get customers due for refill
lpgCustomerSchema.statics.getCustomersDueForRefill = function(userId, daysAhead = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() + daysAhead);
  
  return this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId), isActive: true } },
    {
      $addFields: {
        lastRefillDate: {
          $max: '$refillHistory.refillDate'
        },
        avgConsumption: {
          $avg: {
            $map: {
              input: '$refillHistory',
              as: 'refill',
              in: {
                $multiply: [
                  { $toDouble: { $substr: ['$$refill.cylinderType', 0, -2] } },
                  '$$refill.quantity'
                ]
              }
            }
          }
        }
      }
    },
    {
      $addFields: {
        nextExpectedRefill: {
          $dateAdd: {
            startDate: '$lastRefillDate',
            unit: 'day',
            amount: {
              $ceil: {
                $divide: [
                  { $multiply: [30, 14.2] },
                  { $ifNull: ['$avgConsumption', 14.2] }
                ]
              }
            }
          }
        }
      }
    },
    {
      $match: {
        nextExpectedRefill: { $lte: cutoffDate }
      }
    }
  ]);
};

// Static method to get top customers by spending
lpgCustomerSchema.statics.getTopCustomers = function(userId, limit = 10) {
  return this.find({ userId, isActive: true })
    .sort({ totalSpent: -1 })
    .limit(limit)
    .select('name phone totalSpent totalRefills loyaltyTier');
};

module.exports = mongoose.model('LPGCustomer', lpgCustomerSchema);