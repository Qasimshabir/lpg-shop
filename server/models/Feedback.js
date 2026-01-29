const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'User is required']
  },
  category: {
    type: String,
    required: [true, 'Please specify feedback category'],
    enum: ['bug', 'feature', 'general', 'complaint', 'suggestion'],
    default: 'general'
  },
  title: {
    type: String,
    required: [true, 'Please add a feedback title'],
    trim: true,
    maxlength: [100, 'Title cannot be more than 100 characters']
  },
  message: {
    type: String,
    required: [true, 'Please add feedback message'],
    trim: true,
    maxlength: [1000, 'Message cannot be more than 1000 characters']
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  status: {
    type: String,
    enum: ['pending', 'in_progress', 'resolved', 'rejected'],
    default: 'pending'
  },
  adminResponse: {
    type: String,
    trim: true,
    maxlength: [500, 'Admin response cannot be more than 500 characters']
  },
  responseDate: {
    type: Date
  },
  screenshots: [{
    type: String, // Base64 or URL
    maxlength: [500, 'Screenshot path too long']
  }],
  deviceInfo: {
    platform: String,
    version: String,
    model: String
  },
  isPublic: {
    type: Boolean,
    default: false // Whether feedback can be shown to other users
  }
}, {
  timestamps: true
});

// Create indexes for better performance
feedbackSchema.index({ userId: 1 });
feedbackSchema.index({ category: 1 });
feedbackSchema.index({ status: 1 });
feedbackSchema.index({ priority: 1 });
feedbackSchema.index({ createdAt: -1 });

// Static method to get feedback statistics
feedbackSchema.statics.getFeedbackStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);
  
  const categoryStats = await this.aggregate([
    {
      $group: {
        _id: '$category',
        count: { $sum: 1 }
      }
    }
  ]);
  
  return { statusStats: stats, categoryStats };
};

// Static method to get pending feedbacks
feedbackSchema.statics.getPendingFeedbacks = function(limit = 10) {
  return this.find({ status: 'pending' })
    .populate('userId', 'name email shopName')
    .sort({ createdAt: -1 })
    .limit(limit);
};

// Instance method to update status
feedbackSchema.methods.updateStatus = function(status, adminResponse) {
  this.status = status;
  if (adminResponse) {
    this.adminResponse = adminResponse;
    this.responseDate = new Date();
  }
  return this.save();
};

module.exports = mongoose.model('Feedback', feedbackSchema);
