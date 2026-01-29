const mongoose = require('mongoose');

const safetyChecklistSchema = new mongoose.Schema({
  saleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGSale',
    required: true
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGCustomer',
    required: true
  },
  checklistType: {
    type: String,
    enum: ['new-connection', 'refill', 'exchange', 'inspection'],
    required: true
  },
  
  items: [{
    category: { type: String, required: true },
    item: { type: String, required: true },
    checked: { type: Boolean, default: false },
    checkedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    checkedAt: Date,
    notes: String
  }],
  
  customerAcknowledgment: {
    acknowledged: { type: Boolean, default: false },
    signature: String,
    acknowledgedAt: Date,
    acknowledgedBy: String
  },
  
  safetyEquipmentProvided: [{
    equipment: { type: String, required: true },
    quantity: { type: Number, default: 1 },
    serialNumber: String
  }],
  
  safetyInstructionsGiven: { type: Boolean, default: false },
  safetyBrochureProvided: { type: Boolean, default: false },
  emergencyContactVerified: { type: Boolean, default: false },
  
  installationPhotos: [{
    type: String,
    description: String,
    takenAt: Date
  }],
  
  completedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  completedAt: {
    type: Date,
    default: Date.now
  },
  
  status: {
    type: String,
    enum: ['pending', 'in-progress', 'completed', 'failed'],
    default: 'pending'
  },
  
  notes: String
  
}, {
  timestamps: true
});

safetyChecklistSchema.index({ saleId: 1 });
safetyChecklistSchema.index({ customerId: 1 });
safetyChecklistSchema.index({ status: 1, createdAt: -1 });

safetyChecklistSchema.virtual('completionPercentage').get(function() {
  if (this.items.length === 0) return 0;
  const checkedCount = this.items.filter(item => item.checked).length;
  return Math.round((checkedCount / this.items.length) * 100);
});

safetyChecklistSchema.virtual('isComplete').get(function() {
  return this.items.every(item => item.checked) &&
         this.customerAcknowledgment.acknowledged &&
         this.safetyInstructionsGiven &&
         this.emergencyContactVerified;
});

safetyChecklistSchema.methods.checkItem = function(itemId, userId, notes = '') {
  const item = this.items.id(itemId);
  if (!item) {
    throw new Error('Item not found');
  }
  
  item.checked = true;
  item.checkedBy = userId;
  item.checkedAt = new Date();
  if (notes) item.notes = notes;
  
  if (this.isComplete) {
    this.status = 'completed';
  } else if (this.items.some(i => i.checked)) {
    this.status = 'in-progress';
  }
  
  return this.save();
};

safetyChecklistSchema.methods.addAcknowledgment = function(signature, customerName) {
  this.customerAcknowledgment = {
    acknowledged: true,
    signature,
    acknowledgedAt: new Date(),
    acknowledgedBy: customerName
  };
  
  if (this.isComplete) {
    this.status = 'completed';
  }
  
  return this.save();
};

safetyChecklistSchema.statics.getTemplate = function(type) {
  const templates = {
    'new-connection': [
      {
        category: 'Installation',
        items: [
          'Cylinder placed in well-ventilated area',
          'Minimum 1 meter distance from ignition sources',
          'Cylinder placed on stable, level surface',
          'Regulator properly connected',
          'All connections checked for leaks',
          'Safety valve operational',
          'Cylinder secured to prevent tipping'
        ]
      },
      {
        category: 'Customer Education',
        items: [
          'Safety instructions provided in local language',
          'Emergency procedures explained',
          'Leak detection method demonstrated',
          'Proper cylinder handling demonstrated',
          'Emergency contact numbers provided',
          'Safety brochure provided'
        ]
      }
    ],
    'refill': [
      {
        category: 'Cylinder Inspection',
        items: [
          'Cylinder exterior inspected for damage',
          'Valve checked for leaks',
          'Regulator connection inspected',
          'No visible corrosion or dents'
        ]
      }
    ]
  };
  
  return templates[type] || [];
};

module.exports = mongoose.model('SafetyChecklist', safetyChecklistSchema);
