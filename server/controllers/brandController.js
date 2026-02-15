const { getSupabaseClient } = require('../config/supabase');

// @desc    List all brands
// @route   GET /api/brands
// @access  Private
const getBrands = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: brands, error } = await supabase
      .from('brands')
      .select('*')
      .eq('is_active', true)
      .order('title', { ascending: true });

    if (error) throw error;

    res.json({
      success: true,
      count: brands?.length || 0,
      data: brands || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new brand
// @route   POST /api/brands
// @access  Private
const createBrand = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: brand, error } = await supabase
      .from('brands')
      .insert([{
        title: req.body.title,
        description: req.body.description || null,
        logo_url: req.body.logo_url || null,
        is_active: true
      }])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Brand created successfully',
      data: brand
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update brand
// @route   PUT /api/brands/:id
// @access  Private
const updateBrand = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    if (req.body.title !== undefined) updateData.title = req.body.title;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.logo_url !== undefined) updateData.logo_url = req.body.logo_url;
    if (req.body.is_active !== undefined) updateData.is_active = req.body.is_active;

    const { data: brand, error } = await supabase
      .from('brands')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!brand) {
      return res.status(404).json({
        success: false,
        message: 'Brand not found'
      });
    }

    res.json({
      success: true,
      message: 'Brand updated successfully',
      data: brand
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete brand
// @route   DELETE /api/brands/:id
// @access  Private
const deleteBrand = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data, error } = await supabase
      .from('brands')
      .delete()
      .eq('id', req.params.id)
      .select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Brand not found'
      });
    }

    res.json({
      success: true,
      message: 'Brand deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getBrands,
  createBrand,
  updateBrand,
  deleteBrand
};
