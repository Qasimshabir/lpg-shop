const mongoose = require('mongoose');

const deliveryRouteSchema = new mongoose.Schema({
  date: {
    type: Date,
    required: true
  },
  deliveryPersonnel: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DeliveryPersonnel',
    required: true
  },
  sales: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGSale'
  }],
  
  status: {
    type: String,
    enum: ['planned', 'in-progress', 'completed', 'cancelled'],
    default: 'planned'
  },
  
  startTime: Date,
  endTime: Date,
  
  totalDistance: {
    type: Number,
    default: 0
  },
  
  optimizedOrder: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGSale'
  }],
  
  actualOrder: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGSale'
  }],
  
  notes: String
  
}, {
  timestamps: true
});

deliveryRouteSchema.index({ date: 1, deliveryPersonnel: 1 });
deliveryRouteSchema.index({ status: 1 });

deliveryRouteSchema.virtual('duration').get(function() {
  if (!this.startTime || !this.endTime) return null;
  return Math.round((this.endTime - this.startTime) / (1000 * 60)); // minutes
});

module.exports = mongoose.model('DeliveryRoute', deliveryRouteSchema);
