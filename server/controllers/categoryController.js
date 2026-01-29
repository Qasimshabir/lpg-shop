const LPGProduct = require('../models/LPGProduct');
const mongoose = require('mongoose');

// @desc    Get all available categories
// @route   GET /api/categories
// @access  Private
const getCategories = async (req, res, next) => {
  try {
    // Get categories from LPGProduct schema enum
    const categories = [
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
    ];

    res.json({
      success: true,
      count: categories.length,
      data: categories
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get categories with product counts
// @route   GET /api/categories/stats
// @access  Private
const getCategoriesWithStats = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    const categoryStats = await LPGProduct.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId), isActive: true } },
      {
        $group: {
          _id: '$category',
          productCount: { $sum: 1 },
          totalStock: { $sum: '$stock' },
          totalValue: { $sum: { $multiply: ['$stock', '$costPrice'] } },
          avgPrice: { $avg: '$price' }
        }
      },
      { $sort: { productCount: -1 } }
    ]);

    res.json({
      success: true,
      count: categoryStats.length,
      data: categoryStats
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategories,
  getCategoriesWithStats
};