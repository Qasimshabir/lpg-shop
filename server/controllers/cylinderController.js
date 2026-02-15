const { getSupabaseClient } = require('../config/supabase');

// @desc    Register new cylinder
// @route   POST /api/cylinders
// @access  Private
const registerCylinder = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinder, error } = await supabase
      .from('cylinders')
      .insert([{
        serial_number: req.body.serial_number,
        product_id: req.body.product_id || null,
        customer_id: req.body.customer_id || null,
        status: req.body.status || 'available',
        manufacturing_date: req.body.manufacturing_date || null
      }])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Cylinder registered successfully',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all cylinders
// @route   GET /api/cylinders
// @access  Private
const getCylinders = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('cylinders')
      .select('*, lpg_products(name, weight), lpg_customers(name)');

    if (req.query.status) {
      query = query.eq('status', req.query.status);
    }

    if (req.query.customer_id) {
      query = query.eq('customer_id', req.query.customer_id);
    }

    query = query.order('created_at', { ascending: false });

    const { data: cylinders, error } = await query;

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
  registerCylinder,
  getCylinders
};
