const { getSupabaseClient } = require('../config/supabase');
const { saveDataUriToFile } = require('../utils/fileStorage');
const { uploadImage, deleteImage, extractFilePathFromUrl, validateImage } = require('../utils/supabaseStorage');

// @desc    Get all LPG products
// @route   GET /api/products
// @access  Private
const getLPGProducts = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

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
    
    // Debug: Log what we're receiving
    console.log('=== CREATE PRODUCT DEBUG ===');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    console.log('costPrice:', req.body.costPrice);
    console.log('depositAmount:', req.body.depositAmount);
    console.log('refillPrice:', req.body.refillPrice);
    console.log('cylinderType:', req.body.cylinderType);
    console.log('capacity:', req.body.capacity);
    
    // Handle brand_id - if it's a string (brand name) or invalid UUID, set to null
    let brandId = null;
    if (req.body.brand_id) {
      // Check if it's a valid UUID format
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (uuidRegex.test(req.body.brand_id)) {
        brandId = req.body.brand_id;
      }
    }
    
    const productData = {
      user_id: req.user.id,
      name: req.body.name,
      brand_id: brandId,
      category: req.body.category,
      product_type: req.body.productType || 'cylinder',
      cylinder_type: req.body.cylinderType || null,
      capacity: req.body.capacity || null,
      pressure_rating: req.body.pressureRating || null,
      weight: req.body.weight || req.body.capacity || null,
      weight_unit: req.body.weight_unit || 'kg',
      unit: req.body.unit || 'Piece',
      price: req.body.price,
      cost_price: req.body.costPrice || 0,
      deposit_amount: req.body.depositAmount || 0,
      refill_price: req.body.refillPrice || 0,
      stock_quantity: req.body.stock_quantity || req.body.stock || 0,
      reorder_level: req.body.reorder_level || req.body.minStock || 10,
      min_stock: req.body.minStock || 10,
      max_stock: req.body.maxStock || 100,
      description: req.body.description || null,
      image_url: req.body.image_url || null,
      sku: req.body.sku || null,
      barcode: req.body.barcode || null,
      discount: req.body.discount || 0,
      notes: req.body.notes || null,
      tags: req.body.tags || [],
      cylinder_states: req.body.cylinderStates || null,
      inspection_required: req.body.inspectionRequired || false,
      inspection_interval: req.body.inspectionInterval || 60,
      last_inspection_date: req.body.lastInspectionDate || null,
      next_inspection_due: req.body.nextInspectionDue || null,
      certification_number: req.body.certificationNumber || null,
      is_active: req.body.isActive !== undefined ? req.body.isActive : true
    };
    
    console.log('Product data to insert:', JSON.stringify(productData, null, 2));

    // Handle cylinder states if provided
    if (req.body.cylinderStates) {
      productData.cylinder_states = req.body.cylinderStates;
      if (req.body.cylinderStates.filled) {
        productData.stock_quantity = req.body.cylinderStates.filled;
      }
    }

    // Handle image upload to Supabase Storage
    if (req.body.image && req.body.image.startsWith('data:image/')) {
      // Extract base64 data
      const matches = req.body.image.match(/^data:image\/([a-zA-Z]+);base64,(.+)$/);
      if (matches && matches.length === 3) {
        const imageBuffer = Buffer.from(matches[2], 'base64');
        const fileName = `product-${Date.now()}.${matches[1]}`;
        
        // Validate image
        const validation = validateImage(imageBuffer, fileName);
        if (!validation.valid) {
          return res.status(400).json({
            success: false,
            message: validation.error
          });
        }
        
        // Upload to Supabase Storage
        const uploadResult = await uploadImage(imageBuffer, fileName);
        if (uploadResult.success) {
          productData.image_url = uploadResult.url;
        } else {
          return res.status(500).json({
            success: false,
            message: 'Failed to upload image: ' + uploadResult.error
          });
        }
      }
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
    if (req.body.productType !== undefined) updateData.product_type = req.body.productType;
    if (req.body.cylinderType !== undefined) updateData.cylinder_type = req.body.cylinderType;
    if (req.body.capacity !== undefined) updateData.capacity = req.body.capacity;
    if (req.body.pressureRating !== undefined) updateData.pressure_rating = req.body.pressureRating;
    if (req.body.weight !== undefined) updateData.weight = req.body.weight;
    if (req.body.weight_unit !== undefined) updateData.weight_unit = req.body.weight_unit;
    if (req.body.unit !== undefined) updateData.unit = req.body.unit;
    if (req.body.price !== undefined) updateData.price = req.body.price;
    if (req.body.costPrice !== undefined) updateData.cost_price = req.body.costPrice;
    if (req.body.depositAmount !== undefined) updateData.deposit_amount = req.body.depositAmount;
    if (req.body.refillPrice !== undefined) updateData.refill_price = req.body.refillPrice;
    if (req.body.stock_quantity !== undefined) updateData.stock_quantity = req.body.stock_quantity;
    if (req.body.stock !== undefined) updateData.stock_quantity = req.body.stock;
    if (req.body.reorder_level !== undefined) updateData.reorder_level = req.body.reorder_level;
    if (req.body.minStock !== undefined) updateData.min_stock = req.body.minStock;
    if (req.body.maxStock !== undefined) updateData.max_stock = req.body.maxStock;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.sku !== undefined) updateData.sku = req.body.sku;
    if (req.body.barcode !== undefined) updateData.barcode = req.body.barcode;
    if (req.body.discount !== undefined) updateData.discount = req.body.discount;
    if (req.body.notes !== undefined) updateData.notes = req.body.notes;
    if (req.body.tags !== undefined) updateData.tags = req.body.tags;
    if (req.body.cylinderStates !== undefined) updateData.cylinder_states = req.body.cylinderStates;
    if (req.body.inspectionRequired !== undefined) updateData.inspection_required = req.body.inspectionRequired;
    if (req.body.inspectionInterval !== undefined) updateData.inspection_interval = req.body.inspectionInterval;
    if (req.body.lastInspectionDate !== undefined) updateData.last_inspection_date = req.body.lastInspectionDate;
    if (req.body.nextInspectionDue !== undefined) updateData.next_inspection_due = req.body.nextInspectionDue;
    if (req.body.certificationNumber !== undefined) updateData.certification_number = req.body.certificationNumber;
    if (req.body.isActive !== undefined) updateData.is_active = req.body.isActive;
    if (req.body.is_active !== undefined) updateData.is_active = req.body.is_active;

    // Handle image upload to Supabase Storage
    if (req.body.image && req.body.image.startsWith('data:image/')) {
      // Get existing product to delete old image
      const { data: existingProduct } = await supabase
        .from('lpg_products')
        .select('image_url')
        .eq('id', req.params.id)
        .eq('user_id', req.user.id)
        .single();
      
      // Extract base64 data
      const matches = req.body.image.match(/^data:image\/([a-zA-Z]+);base64,(.+)$/);
      if (matches && matches.length === 3) {
        const imageBuffer = Buffer.from(matches[2], 'base64');
        const fileName = `product-${Date.now()}.${matches[1]}`;
        
        // Validate image
        const validation = validateImage(imageBuffer, fileName);
        if (!validation.valid) {
          return res.status(400).json({
            success: false,
            message: validation.error
          });
        }
        
        // Delete old image if exists
        if (existingProduct?.image_url) {
          const oldFilePath = extractFilePathFromUrl(existingProduct.image_url);
          if (oldFilePath) {
            await deleteImage(oldFilePath);
          }
        }
        
        // Upload new image to Supabase Storage
        const uploadResult = await uploadImage(imageBuffer, fileName);
        if (uploadResult.success) {
          updateData.image_url = uploadResult.url;
        } else {
          return res.status(500).json({
            success: false,
            message: 'Failed to upload image: ' + uploadResult.error
          });
        }
      }
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
    
    // Get product to delete image
    const { data: product } = await supabase
      .from('lpg_products')
      .select('image_url')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();
    
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

    // Delete image from Supabase Storage if exists
    if (product?.image_url) {
      const filePath = extractFilePathFromUrl(product.image_url);
      if (filePath) {
        await deleteImage(filePath);
      }
    }

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cylinder state
// @route   PUT /api/products/:id/cylinder-state
// @access  Private
const updateCylinderState = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { state, quantity, operation = 'add' } = req.body;

    // Validate state
    if (!['empty', 'filled', 'sold'].includes(state)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid state. Must be empty, filled, or sold'
      });
    }

    const { data: product, error: fetchError } = await supabase
      .from('lpg_products')
      .select('stock_quantity, cylinder_states')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (fetchError || !product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get current cylinder states or initialize
    const cylinderStates = product.cylinder_states || { empty: 0, filled: 0, sold: 0 };
    
    // Update the specific state
    if (operation === 'add') {
      cylinderStates[state] = (cylinderStates[state] || 0) + quantity;
    } else if (operation === 'subtract') {
      cylinderStates[state] = Math.max(0, (cylinderStates[state] || 0) - quantity);
    } else if (operation === 'set') {
      cylinderStates[state] = quantity;
    }

    // Calculate total stock (empty + filled)
    const newStockQuantity = (cylinderStates.empty || 0) + (cylinderStates.filled || 0);

    const { data: updated, error } = await supabase
      .from('lpg_products')
      .update({ 
        stock_quantity: newStockQuantity,
        cylinder_states: cylinderStates
      })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Cylinder state updated successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Exchange cylinder
// @route   PUT /api/products/:id/exchange
// @access  Private
const exchangeCylinder = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { quantity } = req.body;

    const { data: product, error: fetchError } = await supabase
      .from('lpg_products')
      .select('stock_quantity, cylinder_states')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (fetchError || !product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    // Get current cylinder states or initialize
    const cylinderStates = product.cylinder_states || { empty: 0, filled: 0, sold: 0 };
    
    // Check if we have enough empty cylinders to exchange
    if ((cylinderStates.empty || 0) < quantity) {
      return res.status(400).json({
        success: false,
        message: `Insufficient empty cylinders for exchange. Available: ${cylinderStates.empty || 0}`
      });
    }

    // Exchange: decrease empty, increase filled
    cylinderStates.empty = (cylinderStates.empty || 0) - quantity;
    cylinderStates.filled = (cylinderStates.filled || 0) + quantity;

    // Calculate total stock (empty + filled)
    const newStockQuantity = (cylinderStates.empty || 0) + (cylinderStates.filled || 0);

    const { data: updated, error } = await supabase
      .from('lpg_products')
      .update({ 
        stock_quantity: newStockQuantity,
        cylinder_states: cylinderStates
      })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Cylinder exchange completed successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get low stock products
// @route   GET /api/products/low-stock
// @access  Private
const getLowStockProducts = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: products, error } = await supabase
      .from('lpg_products')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    if (error) throw error;

    const lowStock = products.filter(p => p.stock_quantity <= p.reorder_level);

    res.json({
      success: true,
      count: lowStock.length,
      data: lowStock
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products by category
// @route   GET /api/products/category/:category
// @access  Private
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

// @desc    Get cylinder inventory summary
// @route   GET /api/products/cylinder-summary
// @access  Private
const getCylinderSummary = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: products, error } = await supabase
      .from('lpg_products')
      .select('category, weight, capacity, cylinder_type, stock_quantity, cylinder_states, product_type')
      .eq('user_id', req.user.id)
      .eq('is_active', true)
      .or('product_type.eq.cylinder,category.ilike.%cylinder%');

    if (error) throw error;

    const summary = products.reduce((acc, product) => {
      // Determine the cylinder type key
      let key = product.cylinder_type || `${product.capacity || product.weight || 'Unknown'}kg`;
      
      if (!acc[key]) {
        acc[key] = {
          _id: key,
          type: key,
          totalEmpty: 0,
          totalFilled: 0,
          totalSold: 0,
          totalStock: 0,
          products: 0
        };
      }
      
      // Parse cylinder_states if it exists
      if (product.cylinder_states) {
        const states = typeof product.cylinder_states === 'string' 
          ? JSON.parse(product.cylinder_states) 
          : product.cylinder_states;
        
        acc[key].totalEmpty += states.empty || 0;
        acc[key].totalFilled += states.filled || 0;
        acc[key].totalSold += states.sold || 0;
      } else {
        // Fallback to stock_quantity if cylinder_states not available
        acc[key].totalFilled += product.stock_quantity || 0;
      }
      
      acc[key].totalStock = acc[key].totalEmpty + acc[key].totalFilled + acc[key].totalSold;
      acc[key].products += 1;
      return acc;
    }, {});

    res.json({
      success: true,
      data: Object.values(summary)
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get products due for inspection
// @route   GET /api/products/inspection-due
// @access  Private
const getProductsDueForInspection = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinders, error } = await supabase
      .from('cylinders')
      .select('*, lpg_products(*)')
      .lte('next_inspection_date', new Date().toISOString().split('T')[0])
      .order('next_inspection_date', { ascending: true });

    if (error) throw error;

    res.json({
      success: true,
      count: cylinders?.length || 0,
      data: cylinders || []
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
