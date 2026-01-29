const mongoose = require('mongoose');

const deliveryPersonnelSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [100, 'Name cannot be more than 100 characters']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^[+]?[1-9]?[0-9]{10,14}$/, 'Please add a valid phone number']
  },
  email: {
    type: String,
    trim: true,
    lowercase: true,
    match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Please add a valid email']
  },
  
  vehicleNumber: {
    type: String,
    required: [true, 'Vehicle number is required'],
    trim: true,
    uppercase: true
  },
  vehicleType: {
    type: String,
    enum: ['bike', 'van', 'truck'],
    required: true
  },
  
  licenseNumber: {
    type: String,
    required: [true, 'License number is required'],
    trim: true,
    uppercase: true
  },
  licenseExpiry: {
    type: Date,
    required: true
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  currentLocation: {
    latitude: Number,
    longitude: Number,
    updatedAt: Date
  },
  
  assignedDeliveries: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGSale'
  }],
  
  completedDeliveries: {
    type: Number,
    default: 0
  },
  rating: {
    type: Number,
    default: 5,
    min: 0,
    max: 5
  },
  
  availability: {
    type: String,
    enum: ['available', 'on-delivery', 'off-duty'],
    default: 'available'
  },
  
  notes: String
  
}, {
  timestamps: true
});

deliveryPersonnelSchema.index({ userId: 1, isActive: 1 });
deliveryPersonnelSchema.index({ availability: 1 });

deliveryPersonnelSchema.virtual('isLicenseValid').get(function() {
  return this.licenseExpiry > new Date();
});

module.exports = mongoose.model('DeliveryPersonnel', deliveryPersonnelSchema);
