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

// @desc    Get cylinder by serial number
// @route   GET /api/cylinders/:serialNumber
// @access  Private
const getCylinderBySerial = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinder, error } = await supabase
      .from('cylinders')
      .select('*, lpg_products(name, weight), lpg_customers(name)')
      .eq('serial_number', req.params.serialNumber)
      .single();

    if (error || !cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }

    res.json({
      success: true,
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update cylinder status
// @route   PUT /api/cylinders/:id/status
// @access  Private
const updateCylinderStatus = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinder, error } = await supabase
      .from('cylinders')
      .update({ status: req.body.status })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }

    res.json({
      success: true,
      message: 'Cylinder status updated successfully',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Record inspection
// @route   POST /api/cylinders/:id/inspection
// @access  Private
const recordInspection = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinder, error } = await supabase
      .from('cylinders')
      .update({
        last_refill_date: new Date().toISOString().split('T')[0],
        next_inspection_date: req.body.next_inspection_date
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!cylinder) {
      return res.status(404).json({
        success: false,
        message: 'Cylinder not found'
      });
    }

    res.json({
      success: true,
      message: 'Inspection recorded successfully',
      data: cylinder
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get cylinders due for inspection
// @route   GET /api/cylinders/due-inspection
// @access  Private
const getCylindersDueInspection = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const today = new Date().toISOString().split('T')[0];
    
    const { data: cylinders, error } = await supabase
      .from('cylinders')
      .select('*, lpg_products(name, weight), lpg_customers(name)')
      .lte('next_inspection_date', today)
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

// @desc    Get cylinders with customer
// @route   GET /api/cylinders/with-customer/:customerId
// @access  Private
const getCylindersWithCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: cylinders, error } = await supabase
      .from('cylinders')
      .select('*, lpg_products(name, weight)')
      .eq('customer_id', req.params.customerId)
      .order('created_at', { ascending: false });

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
  getCylinders,
  getCylinderBySerial,
  updateCylinderStatus,
  recordInspection,
  getCylindersDueInspection,
  getCylindersWithCustomer
};
