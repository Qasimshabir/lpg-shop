const mongoose = require('mongoose');

const saleItemSchema = new mongoose.Schema({
  product: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGProduct',
    required: [true, 'Product is required']
  },
  productType: {
    type: String,
    enum: ['cylinder', 'accessory'],
    required: true
  },
  // For cylinders
  cylinderType: {
    type: String,
    enum: ['11.8kg', '15kg', '45.4kg']
  },
  cylinderSerialNumbers: [{
    type: String,
    trim: true,
    uppercase: true
  }],
  isRefill: {
    type: Boolean,
    default: false
  },
  isExchange: {
    type: Boolean,
    default: false
  },
  // For both cylinders and accessories
  quantity: {
    type: Number,
    required: [true, 'Quantity is required'],
    min: [1, 'Quantity must be at least 1']
  },
  unitPrice: {
    type: Number,
    required: [true, 'Unit price is required'],
    min: [0, 'Unit price cannot be negative']
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
  discount: {
    type: Number,
    default: 0,
    min: [0, 'Discount cannot be negative'],
    max: [100, 'Discount cannot be more than 100%']
  },
  discountAmount: {
    type: Number,
    default: 0,
    min: [0, 'Discount amount cannot be negative']
  },
  subtotal: {
    type: Number,
    required: true,
    min: [0, 'Subtotal cannot be negative']
  }
});

const lpgSaleSchema = new mongoose.Schema({
  invoiceNumber: {
    type: String,
    unique: true,
    trim: true,
    uppercase: true
  },
  customer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGCustomer',
    default: null
  },
  customerType: {
    type: String,
    enum: ['walk-in', 'registered'],
    default: 'walk-in'
  },
  // Delivery information
  deliveryRequired: {
    type: Boolean,
    default: false
  },
  deliveryAddress: {
    premises: {
      type: mongoose.Schema.Types.ObjectId
    },
    customAddress: {
      street: String,
      city: String,
      state: String,
      pincode: String,
      landmark: String
    }
  },
  deliveryDate: {
    type: Date
  },
  deliveryTime: {
    type: String,
    enum: ['Morning', 'Afternoon', 'Evening', 'Anytime']
  },
  deliveryStatus: {
    type: String,
    enum: ['Pending', 'Scheduled', 'In Transit', 'Delivered', 'Failed', 'Cancelled'],
    default: 'Pending'
  },
  deliveryCharges: {
    type: Number,
    default: 0,
    min: [0, 'Delivery charges cannot be negative']
  },
  deliveryNotes: {
    type: String,
    trim: true,
    maxlength: [300, 'Delivery notes cannot be more than 300 characters']
  },
  deliveryProof: {
    signature: String,
    photo: String,
    deliveredAt: Date
  },
  // Sale items
  items: [saleItemSchema],
  // Pricing calculations
  subtotal: {
    type: Number,
    default: 0,
    min: [0, 'Subtotal cannot be negative']
  },
  totalDeposit: {
    type: Number,
    default: 0,
    min: [0, 'Total deposit cannot be negative']
  },
  totalRefund: {
    type: Number,
    default: 0,
    min: [0, 'Total refund cannot be negative']
  },
  tax: {
    type: Number,
    default: 0,
    min: [0, 'Tax cannot be negative']
  },
  taxRate: {
    type: Number,
    default: 0,
    min: [0, 'Tax rate cannot be negative'],
    max: [100, 'Tax rate cannot be more than 100%']
  },
  discount: {
    type: Number,
    default: 0,
    min: [0, 'Discount cannot be negative']
  },
  discountType: {
    type: String,
    enum: ['percentage', 'fixed'],
    default: 'percentage'
  },
  discountAmount: {
    type: Number,
    default: 0,
    min: [0, 'Discount amount cannot be negative']
  },
  total: {
    type: Number,
    default: 0,
    min: [0, 'Total cannot be negative']
  },
  // Payment information
  paymentMethod: {
    type: String,
    enum: ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Credit', 'Mixed'],
    default: 'Cash'
  },
  paymentDetails: [{
    method: {
      type: String,
      enum: ['Cash', 'Card', 'UPI', 'Bank Transfer', 'Credit']
    },
    amount: {
      type: Number,
      min: [0, 'Payment amount cannot be negative']
    },
    reference: {
      type: String,
      trim: true
    }
  }],
  paymentStatus: {
    type: String,
    enum: ['Pending', 'Paid', 'Partial', 'Refunded', 'Failed'],
    default: 'Paid'
  },
  paidAmount: {
    type: Number,
    default: 0,
    min: [0, 'Paid amount cannot be negative']
  },
  remainingAmount: {
    type: Number,
    default: 0,
    min: [0, 'Remaining amount cannot be negative']
  },
  // Credit management
  creditUsed: {
    type: Number,
    default: 0,
    min: [0, 'Credit used cannot be negative']
  },
  creditGiven: {
    type: Number,
    default: 0,
    min: [0, 'Credit given cannot be negative']
  },
  // Sale metadata
  soldBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Sold by is required']
  },
  saleType: {
    type: String,
    enum: ['New Sale', 'Refill', 'Exchange', 'Accessory Only'],
    default: 'New Sale'
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot be more than 500 characters']
  },
  status: {
    type: String,
    enum: ['Completed', 'Pending', 'Cancelled', 'Returned'],
    default: 'Completed'
  },
  // Safety and compliance
  safetyCheckCompleted: {
    type: Boolean,
    default: false
  },
  safetyNotes: {
    type: String,
    trim: true,
    maxlength: [300, 'Safety notes cannot be more than 300 characters']
  },
  // Return/exchange tracking
  returnDate: {
    type: Date
  },
  returnReason: {
    type: String,
    trim: true,
    maxlength: [200, 'Return reason cannot be more than 200 characters']
  },
  returnAmount: {
    type: Number,
    default: 0,
    min: [0, 'Return amount cannot be negative']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
lpgSaleSchema.index({ invoiceNumber: 1 });
lpgSaleSchema.index({ customer: 1, createdAt: -1 });
lpgSaleSchema.index({ soldBy: 1, createdAt: -1 });
lpgSaleSchema.index({ status: 1, createdAt: -1 });
lpgSaleSchema.index({ deliveryStatus: 1, deliveryDate: 1 });
lpgSaleSchema.index({ paymentStatus: 1 });
lpgSaleSchema.index({ createdAt: -1 });

// Virtual for net amount (total - refunds + deposits)
lpgSaleSchema.virtual('netAmount').get(function() {
  return this.total - this.totalRefund + this.totalDeposit;
});

// Virtual for profit calculation
lpgSaleSchema.virtual('totalProfit').get(function() {
  // This would need to be calculated based on cost prices from products
  // For now, return 0 as placeholder
  return 0;
});

// Virtual for cylinder count
lpgSaleSchema.virtual('cylinderCount').get(function() {
  return this.items
    .filter(item => item.productType === 'cylinder')
    .reduce((sum, item) => sum + item.quantity, 0);
});

// Virtual for accessory count
lpgSaleSchema.virtual('accessoryCount').get(function() {
  return this.items
    .filter(item => item.productType === 'accessory')
    .reduce((sum, item) => sum + item.quantity, 0);
});

// Pre-save middleware to generate invoice number
lpgSaleSchema.pre('save', async function(next) {
  if (!this.invoiceNumber) {
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0');
    const day = String(today.getDate()).padStart(2, '0');
    const datePrefix = `LPG${year}${month}${day}`;
    
    // Find the last invoice for today
    const lastInvoice = await this.constructor.findOne({
      invoiceNumber: new RegExp(`^${datePrefix}`)
    }).sort({ invoiceNumber: -1 });
    
    let sequence = 1;
    if (lastInvoice) {
      const lastSequence = parseInt(lastInvoice.invoiceNumber.slice(-3));
      sequence = lastSequence + 1;
    }
    
    this.invoiceNumber = `${datePrefix}${String(sequence).padStart(3, '0')}`;
  }
  next();
});

// Pre-save middleware to calculate totals
lpgSaleSchema.pre('save', function(next) {
  // Calculate subtotal
  this.subtotal = this.items.reduce((sum, item) => sum + item.subtotal, 0);
  
  // Calculate total deposits and refunds
  this.totalDeposit = this.items.reduce((sum, item) => sum + (item.depositAmount * item.quantity), 0);
  this.totalRefund = this.items.reduce((sum, item) => sum + (item.refundAmount * item.quantity), 0);
  
  // Calculate discount amount
  if (this.discountType === 'percentage') {
    this.discountAmount = (this.subtotal * this.discount) / 100;
  } else {
    this.discountAmount = this.discount;
  }
  
  // Calculate tax
  const taxableAmount = this.subtotal - this.discountAmount;
  this.tax = (taxableAmount * this.taxRate) / 100;
  
  // Calculate total
  this.total = taxableAmount + this.tax + this.deliveryCharges + this.totalDeposit - this.totalRefund;
  
  // Calculate remaining amount
  this.remainingAmount = Math.max(0, this.total - this.paidAmount - this.creditUsed);
  
  // Determine payment status
  if (this.paidAmount + this.creditUsed >= this.total) {
    this.paymentStatus = 'Paid';
  } else if (this.paidAmount + this.creditUsed > 0) {
    this.paymentStatus = 'Partial';
  } else {
    this.paymentStatus = 'Pending';
  }
  
  next();
});

// Method to add payment
lpgSaleSchema.methods.addPayment = function(method, amount, reference = '') {
  this.paymentDetails.push({
    method,
    amount,
    reference
  });
  
  this.paidAmount += amount;
  
  // Update payment method if it's mixed
  if (this.paymentDetails.length > 1) {
    this.paymentMethod = 'Mixed';
  }
  
  return this.save();
};

// Method to process cylinder exchange
lpgSaleSchema.methods.processCylinderExchange = function() {
  const cylinderItems = this.items.filter(item => item.productType === 'cylinder' && item.isExchange);
  
  // This would integrate with inventory management
  // For now, just mark as processed
  this.status = 'Completed';
  
  return this.save();
};

// Method to schedule delivery
lpgSaleSchema.methods.scheduleDelivery = function(deliveryDate, deliveryTime, notes = '') {
  this.deliveryDate = deliveryDate;
  this.deliveryTime = deliveryTime;
  this.deliveryNotes = notes;
  this.deliveryStatus = 'Scheduled';
  
  return this.save();
};

// Method to update delivery status
lpgSaleSchema.methods.updateDeliveryStatus = function(status, notes = '') {
  this.deliveryStatus = status;
  if (notes) {
    this.deliveryNotes = notes;
  }
  
  if (status === 'Delivered') {
    this.status = 'Completed';
  }
  
  return this.save();
};

// Static method to get sales by date range
lpgSaleSchema.statics.getSalesByDateRange = function(userId, startDate, endDate) {
  return this.find({
    soldBy: userId,
    createdAt: {
      $gte: startDate,
      $lte: endDate
    }
  }).populate('customer', 'name phone')
    .populate('items.product', 'name brand category')
    .sort({ createdAt: -1 });
};

// Static method to get delivery schedule
lpgSaleSchema.statics.getDeliverySchedule = function(userId, date) {
  const startOfDay = new Date(date);
  startOfDay.setHours(0, 0, 0, 0);
  
  const endOfDay = new Date(date);
  endOfDay.setHours(23, 59, 59, 999);
  
  return this.find({
    soldBy: userId,
    deliveryRequired: true,
    deliveryDate: {
      $gte: startOfDay,
      $lte: endOfDay
    },
    deliveryStatus: { $in: ['Scheduled', 'In Transit'] }
  }).populate('customer', 'name phone')
    .sort({ deliveryTime: 1 });
};

// Static method to get pending payments
lpgSaleSchema.statics.getPendingPayments = function(userId) {
  return this.find({
    soldBy: userId,
    paymentStatus: { $in: ['Pending', 'Partial'] },
    status: { $ne: 'Cancelled' }
  }).populate('customer', 'name phone')
    .sort({ createdAt: -1 });
};

module.exports = mongoose.model('LPGSale', lpgSaleSchema);