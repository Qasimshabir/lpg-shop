const mongoose = require('mongoose');

const brandSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Brand title is required'],
      trim: true,
      maxlength: [50, 'Brand title cannot be more than 50 characters'],
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'User is required'],
      index: true,
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Unique index to prevent duplicate brand titles per user
brandSchema.index({ title: 1, userId: 1 }, { unique: true });

module.exports = mongoose.model('Brand', brandSchema);
