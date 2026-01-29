const mongoose = require('mongoose');

const cylinderSchema = new mongoose.Schema({
  serialNumber: {
    type: String,
    required: [true, 'Serial number is required'],
    unique: true,
    uppercase: true,
    trim: true,
    match: [/^CYL-\d{4}-\d{6}$/, 'Invalid serial number format (CYL-YYYY-NNNNNN)']
  },
  
  capacity: {
    type: String,
    required: true,
    enum: ['11.8kg', '15kg', '45.4kg']
  },
  manufacturer: {
    type: String,
    required: true,
    trim: true
  },
  manufacturingDate: {
    type: Date,
    required: true,
    validate: {
      validator: function(v) {
        return v <= new Date();
      },
      message: 'Manufacturing date cannot be in future'
    }
  },
  
  tareWeight: {
    type: Number,
    required: true,
    min: [0, 'Tare weight cannot be negative']
  },
  
  certificationNumber: {
    type: String,
    required: true,
    trim: true
  },
  certificationAuthority: {
    type: String,
    required: true
  },
  
  lastHydrostaticTest: {
    type: Date
  },
  nextTestDue: {
    type: Date,
    required: true
  },
  inspectionHistory: [{
    date: { type: Date, required: true },
    type: { type: String, enum: ['visual', 'hydrostatic', 'ultrasonic'], required: true },
    result: { type: String, enum: ['passed', 'failed', 'conditional'], required: true },
    inspector: { type: String, required: true },
    certificationNumber: String,
    nextDueDate: Date,
    notes: String
  }],
  
  status: {
    type: String,
    enum: ['in-stock', 'with-customer', 'in-transit', 'under-inspection', 'condemned'],
    default: 'in-stock',
    required: true
  },
  
  currentLocation: {
    type: { type: String, enum: ['warehouse', 'customer', 'supplier', 'testing-facility'], default: 'warehouse' },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'LPGCustomer' },
    premisesId: { type: mongoose.Schema.Types.ObjectId },
    updatedAt: { type: Date, default: Date.now }
  },
  
  depositAmount: {
    type: Number,
    default: 0,
    min: [0, 'Deposit amount cannot be negative']
  },
  depositPaidBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGCustomer'
  },
  depositDate: Date,
  
  history: [{
    action: { type: String, enum: ['purchased', 'filled', 'sold', 'exchanged', 'returned', 'inspected', 'condemned'], required: true },
    date: { type: Date, default: Date.now, required: true },
    performedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'LPGCustomer' },
    saleId: { type: mongoose.Schema.Types.ObjectId, ref: 'LPGSale' },
    fromLocation: String,
    toLocation: String,
    notes: String
  }],
  
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  condemnationDate: Date,
  condemnationReason: String
  
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

cylinderSchema.index({ serialNumber: 1 }, { unique: true });
cylinderSchema.index({ userId: 1, status: 1 });
cylinderSchema.index({ userId: 1, nextTestDue: 1 });
cylinderSchema.index({ 'currentLocation.customerId': 1 });
cylinderSchema.index({ capacity: 1, status: 1 });

cylinderSchema.virtual('isInspectionDue').get(function() {
  if (!this.nextTestDue) return false;
  return new Date() > this.nextTestDue;
});

cylinderSchema.virtual('daysUntilInspection').get(function() {
  if (!this.nextTestDue) return null;
  const diff = this.nextTestDue - new Date();
  return Math.ceil(diff / (1000 * 60 * 60 * 24));
});

cylinderSchema.methods.addHistory = function(action, performedBy, additionalData = {}) {
  this.history.push({
    action,
    date: new Date(),
    performedBy,
    ...additionalData
  });
  return this.save();
};

cylinderSchema.methods.updateLocation = function(locationType, customerId = null, premisesId = null) {
  this.currentLocation = {
    type: locationType,
    customerId,
    premisesId,
    updatedAt: new Date()
  };
  return this.save();
};

cylinderSchema.methods.recordInspection = function(inspectionData) {
  this.inspectionHistory.push(inspectionData);
  
  if (inspectionData.result === 'passed') {
    this.lastHydrostaticTest = inspectionData.date;
    this.nextTestDue = inspectionData.nextDueDate;
  } else if (inspectionData.result === 'failed') {
    this.status = 'condemned';
    this.condemnationDate = new Date();
    this.condemnationReason = inspectionData.notes;
  }
  
  return this.save();
};

cylinderSchema.statics.getDueForInspection = function(userId, daysAhead = 30) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() + daysAhead);
  
  return this.find({
    userId,
    status: { $ne: 'condemned' },
    nextTestDue: { $lte: cutoffDate }
  }).sort({ nextTestDue: 1 });
};

cylinderSchema.statics.getAvailable = function(userId, capacity = null) {
  const query = {
    userId,
    status: 'in-stock',
    isActive: true
  };
  
  if (capacity) {
    query.capacity = capacity;
  }
  
  return this.find(query);
};

module.exports = mongoose.model('Cylinder', cylinderSchema);
