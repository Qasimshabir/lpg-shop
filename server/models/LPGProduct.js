const mongoose = require('mongoose');

const lpgProductSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  name: {
    type: String,
    required: [true, 'Please add a product name'],
    trim: true,
    maxlength: [100, 'Product name cannot be more than 100 characters']
  },
  brand: {
    type: String,
    required: [true, 'Please add a brand name'],
    trim: true,
    maxlength: [50, 'Brand name cannot be more than 50 characters']
  },
  brandId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Brand',
    required: false
  },
  category: {
    type: String,
    required: [true, 'Please add a category'],
    enum: [
      'LPG Cylinder',
      'Gas Pipe',
      'Regulator',
      'Gas Stove',
      'Gas Tandoor',
      'Gas Heater',
      'LPG Instant Geyser',
      'Safety Equipment',
      'Accessories',
      'Other'
    ]
  },
  productType: {
    type: String,
    required: [true, 'Please specify product type'],
    enum: ['cylinder', 'accessory'],
    default: 'cylinder'
  },
  // Cylinder-specific fields
  cylinderType: {
    type: String,
    enum: ['11.8kg', '15kg', '45.4kg'],
    required: function() {
      return this.productType === 'cylinder';
    }
  },
  capacity: {
    type: Number, // in kg
    required: function() {
      return this.productType === 'cylinder';
    }
  },
  pressureRating: {
    type: String, // e.g., "15 bar"
    required: function() {
      return this.productType === 'cylinder';
    }
  },
  // Cylinder states for inventory tracking
  cylinderStates: {
    empty: {
      type: Number,
      default: 0,
      min: [0, 'Empty cylinder count cannot be negative']
    },
    filled: {
      type: Number,
      default: 0,
      min: [0, 'Filled cylinder count cannot be negative']
    },
    sold: {
      type: Number,
      default: 0,
      min: [0, 'Sold cylinder count cannot be negative']
    }
  },
  // For accessories
  unit: {
    type: String,
    enum: ['Piece', 'Set', 'Meter', 'Kg'],
    default: function() {
      return this.productType === 'cylinder' ? 'Piece' : 'Piece';
    }
  },
  stock: {
    type: Number,
    default: 0,
    min: [0, 'Stock cannot be negative']
  },
  minStock: {
    type: Number,
    default: 5,
    min: [0, 'Minimum stock cannot be negative']
  },
  maxStock: {
    type: Number,
    default: 100,
    min: [1, 'Maximum stock must be at least 1']
  },
  // Pricing
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative']
  },
  costPrice: {
    type: Number,
    required: [true, 'Cost price is required'],
    min: [0, 'Cost price cannot be negative']
  },
  depositAmount: {
    type: Number,
    default: 0,
    min: [0, 'Deposit amount cannot be negative']
  },
  refillPrice: {
    type: Number,
    default: function() {
      return this.productType === 'cylinder' ? this.price * 0.8 : 0;
    }
  },
  // Product details
  sku: {
    type: String,
    unique: true,
    trim: true,
    uppercase: true
  },
  barcode: {
    type: String,
    trim: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  images: [{
    type: String // Base64 or URL
  }],
  // Supplier information
  supplier: {
    name: {
      type: String,
      trim: true,
      maxlength: [100, 'Supplier name cannot be more than 100 characters']
    },
    contact: {
      type: String,
      trim: true,
      maxlength: [15, 'Contact cannot be more than 15 characters']
    },
    email: {
      type: String,
      trim: true,
      lowercase: true
    }
  },
  // Safety and compliance
  inspectionRequired: {
    type: Boolean,
    default: function() {
      return this.productType === 'cylinder';
    }
  },
  inspectionInterval: {
    type: Number, // in months
    default: 60 // 5 years for LPG cylinders
  },
  lastInspectionDate: {
    type: Date
  },
  nextInspectionDue: {
    type: Date
  },
  certificationNumber: {
    type: String,
    trim: true
  },
  // General fields
  tags: [{
    type: String,
    trim: true
  }],
  discount: {
    type: Number,
    default: 0,
    min: [0, 'Discount cannot be negative'],
    max: [100, 'Discount cannot be more than 100%']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  notes: {
    type: String,
    trim: true,
    maxlength: [500, 'Notes cannot be more than 500 characters']
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexes
lpgProductSchema.index({ userId: 1, category: 1 });
lpgProductSchema.index({ userId: 1, productType: 1 });
lpgProductSchema.index({ userId: 1, cylinderType: 1 });
lpgProductSchema.index({ sku: 1 });
lpgProductSchema.index({ name: 'text', brand: 'text', description: 'text' });

// Virtual for total cylinder count
lpgProductSchema.virtual('totalCylinders').get(function() {
  if (this.productType === 'cylinder') {
    return this.cylinderStates.empty + this.cylinderStates.filled;
  }
  return 0;
});

// Virtual for available cylinders (filled)
lpgProductSchema.virtual('availableCylinders').get(function() {
  if (this.productType === 'cylinder') {
    return this.cylinderStates.filled;
  }
  return this.stock;
});

// Virtual for stock status
lpgProductSchema.virtual('stockStatus').get(function() {
  const available = this.productType === 'cylinder' ? this.cylinderStates.filled : this.stock;
  
  if (available === 0) return 'Out of Stock';
  if (available <= this.minStock) return 'Low Stock';
  if (available >= this.maxStock) return 'Overstock';
  return 'In Stock';
});

// Virtual for profit margin
lpgProductSchema.virtual('profitMargin').get(function() {
  if (this.costPrice === 0) return 0;
  return ((this.price - this.costPrice) / this.costPrice * 100).toFixed(2);
});

// Virtual for final price after discount
lpgProductSchema.virtual('finalPrice').get(function() {
  return this.price - (this.price * this.discount / 100);
});

// Pre-save middleware to generate SKU
lpgProductSchema.pre('save', function(next) {
  if (!this.sku) {
    const brandCode = this.brand.substring(0, 3).toUpperCase();
    const categoryCode = this.category.replace(/\s+/g, '').substring(0, 3).toUpperCase();
    const timestamp = Date.now().toString().slice(-4);
    this.sku = `${brandCode}${categoryCode}${timestamp}`;
  }
  next();
});

// Pre-save middleware to calculate next inspection date
lpgProductSchema.pre('save', function(next) {
  if (this.productType === 'cylinder' && this.lastInspectionDate && this.inspectionInterval) {
    const nextDate = new Date(this.lastInspectionDate);
    nextDate.setMonth(nextDate.getMonth() + this.inspectionInterval);
    this.nextInspectionDue = nextDate;
  }
  next();
});

// Method to update cylinder state
lpgProductSchema.methods.updateCylinderState = function(state, quantity, operation = 'add') {
  if (this.productType !== 'cylinder') {
    throw new Error('This method is only for cylinder products');
  }
  
  if (!['empty', 'filled', 'sold'].includes(state)) {
    throw new Error('Invalid cylinder state');
  }
  
  if (operation === 'add') {
    this.cylinderStates[state] += quantity;
  } else if (operation === 'subtract') {
    this.cylinderStates[state] = Math.max(0, this.cylinderStates[state] - quantity);
  }
  
  return this.save();
};

// Method to exchange cylinder (empty for filled)
lpgProductSchema.methods.exchangeCylinder = function(quantity) {
  if (this.productType !== 'cylinder') {
    throw new Error('This method is only for cylinder products');
  }
  
  if (this.cylinderStates.filled < quantity) {
    throw new Error('Insufficient filled cylinders for exchange');
  }
  
  this.cylinderStates.filled -= quantity;
  this.cylinderStates.empty += quantity;
  this.cylinderStates.sold += quantity;
  
  return this.save();
};

// Static method to get low stock products
lpgProductSchema.statics.getLowStockProducts = function(userId) {
  return this.find({
    userId,
    isActive: true,
    $or: [
      {
        productType: 'cylinder',
        'cylinderStates.filled': { $lte: this.minStock }
      },
      {
        productType: 'accessory',
        stock: { $lte: this.minStock }
      }
    ]
  });
};

module.exports = mongoose.model('LPGProduct', lpgProductSchema);