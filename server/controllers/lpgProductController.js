const { getSupabaseClient } = require('../config/supabase');
const { saveDataUriToFile } = require('../utils/fileStorage');

// @desc    Get all LPG products
// @route   GET /api/products
// @access  Private
const getLPGProducts = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    // Build query
    let query = supabase
      .from('lpg_products')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id);
    
    if (req.query.category) {
      query = query.eq('category', req.query.category);
    }
    
    if (req.query.is_active !== undefined) {
      query = query.eq('is_active', req.query.is_active === 'true');
    }

    if (req.query.search) {
      query = query.or(`name.ilike.%${req.query.search}%,sku.ilike.%${req.query.search}%,description.ilike.%${req.query.search}%`);
    }

    // Apply pagination and sorting
    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data: products, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: products?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: products || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single LPG product
// @route   GET /api/products/:id
// @access  Private
const getLPGProduct = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: product, error } = await supabase
      .from('lpg_products')
      .select('*')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (error || !product) {
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
// @route   POST /api/products
// @access  Private
const createLPGProduct = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const productData = {
      user_id: req.user.id,
      name: req.body.name,
      brand_id: req.body.brand_id || null,
      category: req.body.category,
      weight: req.body.weight || null,
      weight_unit: req.body.weight_unit || 'kg',
      price: req.body.price,
      stock_quantity: req.body.stock_quantity || 0,
      reorder_level: req.body.reorder_level || 10,
      description: req.body.description || null,
      image_url: req.body.image_url || null,
      sku: req.body.sku || null,
      is_active: req.body.is_active !== undefined ? req.body.is_active : true
    };

    // Handle image upload if provided
    if (req.body.image && req.body.image.startsWith('data:image/')) {
      productData.image_url = await saveDataUriToFile(req.body.image, 'products');
    }

    const { data: product, error } = await supabase
      .from('lpg_products')
      .insert([productData])
      .select()
      .single();

    if (error) throw error;

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
// @route   PUT /api/products/:id
// @access  Private
const updateLPGProduct = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Check if product exists
    const { data: existing } = await supabase
      .from('lpg_products')
      .select('id')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    const updateData = {};
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (req.body.brand_id !== undefined) updateData.brand_id = req.body.brand_id;
    if (req.body.category !== undefined) updateData.category = req.body.category;
    if (req.body.weight !== undefined) updateData.weight = req.body.weight;
    if (req.body.weight_unit !== undefined) updateData.weight_unit = req.body.weight_unit;
    if (req.body.price !== undefined) updateData.price = req.body.price;
    if (req.body.stock_quantity !== undefined) updateData.stock_quantity = req.body.stock_quantity;
    if (req.body.reorder_level !== undefined) updateData.reorder_level = req.body.reorder_level;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.sku !== undefined) updateData.sku = req.body.sku;
    if (req.body.is_active !== undefined) updateData.is_active = req.body.is_active;

    // Handle image upload
    if (req.body.image && req.body.image.startsWith('data:image/')) {
      updateData.image_url = await saveDataUriToFile(req.body.image, 'products');
    } else if (req.body.image_url !== undefined) {
      updateData.image_url = req.body.image_url;
    }

    const { data: product, error } = await supabase
      .from('lpg_products')
      .update(updateData)
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

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
// @route   DELETE /api/products/:id
// @access  Private
const deleteLPGProduct = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data, error } = await supabase
      .from('lpg_products')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Simplified methods for Supabase
const updateCylinderState = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const exchangeCylinder = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getLowStockProducts = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: products, error } = await supabase
      .from('lpg_products')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('is_active', true)
      .filter('stock_quantity', 'lte', 'reorder_level')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: products?.length || 0,
      data: products || []
    });
  } catch (error) {
    next(error);
  }
};

const getProductsByCategory = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { category } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const { data: products, error, count } = await supabase
      .from('lpg_products')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id)
      .eq('category', category)
      .eq('is_active', true)
      .order('name', { ascending: true })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.json({
      success: true,
      count: products?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: products || []
    });
  } catch (error) {
    next(error);
  }
};

const getCylinderSummary = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getProductsDueForInspection = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
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
