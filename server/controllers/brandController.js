const Brand = require('../models/Brand');

// @desc    List all brands for the current user
// @route   GET /api/brands
// @access  Private
const getBrands = async (req, res, next) => {
  try {
    const brands = await Brand.find({ userId: req.user.id }).sort({ title: 1 });
    res.json({
      success: true,
      count: brands.length,
      data: brands,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a new brand for the current user
// @route   POST /api/brands
// @access  Private
const createBrand = async (req, res, next) => {
  try {
    const { title } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Brand title is required' });
    }
    // Check for duplicate
    const existing = await Brand.findOne({ title: title.trim(), userId: req.user.id });
    if (existing) {
      return res.status(400).json({ success: false, message: 'Brand already exists' });
    }
    const brand = await Brand.create({ title: title.trim(), userId: req.user.id });
    res.status(201).json({
      success: true,
      message: 'Brand created successfully',
      data: brand,
    });
  } catch (error) {
    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Brand already exists' });
    }
    next(error);
  }
};

// @desc    Update a brand for the current user
// @route   PUT /api/brands/:id
// @access  Private
const updateBrand = async (req, res, next) => {
  try {
    const { title } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ success: false, message: 'Brand title is required' });
    }
    const brand = await Brand.findOneAndUpdate(
      { _id: req.params.id, userId: req.user.id },
      { title: title.trim() },
      { new: true, runValidators: true }
    );
    if (!brand) {
      return res.status(404).json({ success: false, message: 'Brand not found' });
    }
    res.json({ success: true, message: 'Brand updated successfully', data: brand });
  } catch (error) {
    // Handle duplicate key error
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Brand title already exists' });
    }
    next(error);
  }
};

// @desc    Delete a brand for the current user
// @route   DELETE /api/brands/:id
// @access  Private
const deleteBrand = async (req, res, next) => {
  try {
    const brand = await Brand.findOneAndDelete({ _id: req.params.id, userId: req.user.id });
    if (!brand) {
      return res.status(404).json({ success: false, message: 'Brand not found' });
    }
    res.json({ success: true, message: 'Brand deleted successfully' });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getBrands,
  createBrand,
  updateBrand,
  deleteBrand,
};
