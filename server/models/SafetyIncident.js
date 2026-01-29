const mongoose = require('mongoose');

const safetyIncidentSchema = new mongoose.Schema({
  incidentDate: {
    type: Date,
    required: true
  },
  reportedDate: {
    type: Date,
    default: Date.now
  },
  reportedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  incidentType: {
    type: String,
    enum: ['leak', 'fire', 'explosion', 'injury', 'near-miss', 'equipment-failure', 'other'],
    required: true
  },
  severity: {
    type: String,
    enum: ['minor', 'moderate', 'severe', 'critical'],
    required: true
  },
  
  location: {
    type: String,
    required: true
  },
  customerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'LPGCustomer'
  },
  cylinderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Cylinder'
  },
  
  description: {
    type: String,
    required: true,
    maxlength: 2000
  },
  immediateAction: {
    type: String,
    required: true,
    maxlength: 1000
  },
  
  rootCause: String,
  contributingFactors: [String],
  correctiveAction: String,
  preventiveAction: String,
  
  status: {
    type: String,
    enum: ['reported', 'investigating', 'action-taken', 'resolved', 'closed'],
    default: 'reported'
  },
  
  investigationReport: String,
  investigatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  investigationDate: Date,
  
  attachments: [{
    type: { type: String, enum: ['photo', 'document', 'video'] },
    url: String,
    description: String,
    uploadedAt: Date
  }],
  
  regulatoryReported: {
    type: Boolean,
    default: false
  },
  regulatoryReportDate: Date,
  regulatoryReferenceNumber: String,
  
  followUpRequired: {
    type: Boolean,
    default: false
  },
  followUpDate: Date,
  followUpNotes: String,
  
  closedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  closedAt: Date,
  closureNotes: String
  
}, {
  timestamps: true
});

safetyIncidentSchema.index({ incidentDate: -1 });
safetyIncidentSchema.index({ status: 1 });
safetyIncidentSchema.index({ severity: 1, status: 1 });
safetyIncidentSchema.index({ customerId: 1 });
safetyIncidentSchema.index({ cylinderId: 1 });

safetyIncidentSchema.virtual('daysSinceIncident').get(function() {
  const diff = Date.now() - this.incidentDate;
  return Math.floor(diff / (1000 * 60 * 60 * 24));
});

safetyIncidentSchema.virtual('isOverdue').get(function() {
  if (this.status === 'closed') return false;
  return this.daysSinceIncident > 7;
});

safetyIncidentSchema.methods.updateStatus = function(newStatus, userId, notes = '') {
  this.status = newStatus;
  
  if (newStatus === 'closed') {
    this.closedBy = userId;
    this.closedAt = new Date();
    this.closureNotes = notes;
  }
  
  return this.save();
};

safetyIncidentSchema.statics.getOpenIncidents = function(userId) {
  return this.find({
    reportedBy: userId,
    status: { $ne: 'closed' }
  }).sort({ severity: -1, incidentDate: -1 });
};

module.exports = mongoose.model('SafetyIncident', safetyIncidentSchema);
