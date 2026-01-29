const LPGProduct = require('../models/LPGProduct');
const { saveDataUriToFile } = require('../utils/fileStorage');

// @desc    Get all LPG products
// @route   GET /api/lpg/products
// @access  Private
const getLPGProducts = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Build query - filter by user
    let query = { userId: req.user.id };
    
    if (req.query.category) {
      query.category = req.query.category;
    }
    
    if (req.query.productType) {
      query.productType = req.query.productType;
    }
    
    if (req.query.cylinderType) {
      query.cylinderType = req.query.cylinderType;
    }
    
    if (req.query.brand) {
      query.brand = new RegExp(req.query.brand, 'i');
    }
    
    if (req.query.isActive !== undefined) {
      query.isActive = req.query.isActive === 'true';
    }

    if (req.query.search) {
      query.$or = [
        { name: new RegExp(req.query.search, 'i') },
        { brand: new RegExp(req.query.search, 'i') },
        { sku: new RegExp(req.query.search, 'i') },
        { description: new RegExp(req.query.search, 'i') }
      ];
    }

    // Filter by stock status
    if (req.query.stockStatus) {
      switch (req.query.stockStatus) {
        case 'low':
          query.$expr = {
            $or: [
              {
                $and: [
                  { $eq: ['$productType', 'cylinder'] },
                  { $lte: ['$cylinderStates.filled', '$minStock'] }
                ]
              },
              {
                $and: [
                  { $eq: ['$productType', 'accessory'] },
                  { $lte: ['$stock', '$minStock'] }
                ]
              }
            ]
          };
          break;
        case 'out':
          query.$expr = {
            $or: [
              {
                $and: [
                  { $eq: ['$productType', 'cylinder'] },
                  { $eq: ['$cylinderStates.filled', 0] }
                ]
              },
              {
                $and: [
                  { $eq: ['$productType', 'accessory'] },
                  { $eq: ['$stock', 0] }
                ]
              }
            ]
          };
          break;
      }
    }

    const products = await LPGProduct.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await LPGProduct.countDocuments(query);

    res.json({
      success: true,
      count: products.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single LPG product
// @route   GET /api/lpg/products/:id
// @access  Private
const getLPGProduct = async (req, res, next) => {
  try {
    const product = await LPGProduct.findOne({ _id: req.params.id, userId: req.user.id });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new LPG product
// @route   POST /api/lpg/products
// @access  Private
const createLPGProduct = async (req, res, next) => {
  try {
    const productData = {
      ...req.body,
      userId: req.user.id
    };

    // Handle image uploads
    if (req.body.images && Array.isArray(req.body.images)) {
      const imageUrls = [];
      for (const imageData of req.body.images) {
        if (imageData.startsWith('data:image/')) {
          const imageUrl = await saveDataUriToFile(imageData, 'products');
          imageUrls.push(imageUrl);
        } else {
          imageUrls.push(imageData);
        }
      }
      productData.images = imageUrls;
    }

    // Set default values based on product type
    if (productData.productType === 'cylinder') {
      if (!productData.cylinderStates) {
        productData.cylinderStates = {
          empty: 0,
          filled: productData.stock || 0,
          sold: 0
        };
      }
      
      // Set capacity based on cylinder type
      if (productData.cylinderType) {
        productData.capacity = parseFloat(productData.cylinderType.replace('kg', ''));
      }
    }

    const product = await LPGProduct.create(productData);

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update LPG product
// @route   PUT /api/lpg/products/:id
// @access  Private
const updateLPGProduct = async (req, res, next) => {
  try {
    let product = await LPGProduct.findOne({ _id: req.params.id, userId: req.user.id });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    const updateData = { ...req.body };

    // Handle image uploads
    if (req.body.images && Array.isArray(req.body.images)) {
      const imageUrls = [];
      for (const imageData of req.body.images) {
        if (imageData.startsWith('data:image/')) {
          const imageUrl = await saveDataUriToFile(imageData, 'products');
          imageUrls.push(imageUrl);
        } else {
          imageUrls.push(imageData);
        }
      }
      updateData.images = imageUrls;
    }

    // Update capacity if cylinder type changed
    if (updateData.cylinderType && updateData.productType === 'cylinder') {
      updateData.capacity = parseFloat(updateData.cylinderType.replace('kg', ''));
    }

    product = await LPGProduct.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      updateData,
      {
        new: true,
        runValidators: true
      }
    );

    res.json({
      success: true,
      message: 'Product updated successfully',
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete LPG product
// @route   DELETE /api/lpg/products/:id
// @access  Private
const deleteLPGProduct = async (req, res, next) => {
  try {
    const product = await LPGProduct.findOne({ _id: req.params.id, userId: req.user.id });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    await product.deleteOne();

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cylinder state
// @route   PUT /api/lpg/products/:id/cylinder-state
// @access  Private
const updateCylinderState = async (req, res, next) => {
  try {
    const { state, quantity, operation = 'add' } = req.body;

    const product = await LPGProduct.findOne({ _id: req.params.id, userId: req.user.id });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    if (product.productType !== 'cylinder') {
      return res.status(400).json({
        success: false,
        message: 'This operation is only for cylinder products'
      });
    }

    await product.updateCylinderState(state, quantity, operation);

    res.json({
      success: true,
      message: 'Cylinder state updated successfully',
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Exchange cylinder
// @route   PUT /api/lpg/products/:id/exchange
// @access  Private
const exchangeCylinder = async (req, res, next) => {
  try {
    const { quantity } = req.body;

    const product = await LPGProduct.findOne({ _id: req.params.id, userId: req.user.id });

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    await product.exchangeCylinder(quantity);

    res.json({
      success: true,
      message: 'Cylinder exchange completed successfully',
      data: product
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get low stock products
// @route   GET /api/lpg/products/low-stock
// @access  Private
const getLowStockProducts = async (req, res, next) => {
  try {
    const products = await LPGProduct.find({
      userId: req.user.id,
      isActive: true,
      $or: [
        {
          productType: 'cylinder',
          $expr: { $lte: ['$cylinderStates.filled', '$minStock'] }
        },
        {
          productType: 'accessory',
          $expr: { $lte: ['$stock', '$minStock'] }
        }
      ]
    }).sort({ createdAt: -1 });

    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products by category
// @route   GET /api/lpg/products/category/:category
// @access  Private
const getProductsByCategory = async (req, res, next) => {
  try {
    const { category } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const products = await LPGProduct.find({
      userId: req.user.id,
      category,
      isActive: true
    })
      .sort({ name: 1 })
      .skip(skip)
      .limit(limit);

    const total = await LPGProduct.countDocuments({
      userId: req.user.id,
      category,
      isActive: true
    });

    res.json({
      success: true,
      count: products.length,
      total,
      page,
      pages: Math.ceil(total / limit),
      data: products
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cylinder inventory summary
// @route   GET /api/lpg/products/cylinder-summary
// @access  Private
const getCylinderSummary = async (req, res, next) => {
  try {
    const summary = await LPGProduct.aggregate([
      {
        $match: {
          userId: req.user._id,
          productType: 'cylinder',
          isActive: true
        }
      },
      {
        $group: {
          _id: '$cylinderType',
          totalEmpty: { $sum: '$cylinderStates.empty' },
          totalFilled: { $sum: '$cylinderStates.filled' },
          totalSold: { $sum: '$cylinderStates.sold' },
          products: { $push: '$$ROOT' }
        }
      },
      {
        $addFields: {
          totalCylinders: { $add: ['$totalEmpty', '$totalFilled'] },
          availableForSale: '$totalFilled'
        }
      },
      {
        $sort: { _id: 1 }
      }
    ]);

    res.json({
      success: true,
      data: summary
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products due for inspection
// @route   GET /api/lpg/products/inspection-due
// @access  Private
const getProductsDueForInspection = async (req, res, next) => {
  try {
    const daysAhead = parseInt(req.query.days) || 30;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() + daysAhead);

    const products = await LPGProduct.find({
      userId: req.user.id,
      productType: 'cylinder',
      inspectionRequired: true,
      isActive: true,
      $or: [
        { nextInspectionDue: { $lte: cutoffDate } },
        { nextInspectionDue: null, lastInspectionDate: null }
      ]
    }).sort({ nextInspectionDue: 1 });

    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getLPGProducts,
  getLPGProduct,
  createLPGProduct,
  updateLPGProduct,
  deleteLPGProduct,
  updateCylinderState,
  exchangeCylinder,
  getLowStockProducts,
  getProductsByCategory,
  getCylinderSummary,
  getProductsDueForInspection
};