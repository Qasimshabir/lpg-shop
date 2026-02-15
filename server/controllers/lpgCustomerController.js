const { getSupabaseClient } = require('../config/supabase');

// @desc    Get all LPG customers
// @route   GET /api/customers
// @access  Private
const getLPGCustomers = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    let query = supabase
      .from('lpg_customers')
      .select('*', { count: 'exact' })
      .eq('user_id', req.user.id);

    if (req.query.search) {
      query = query.or(`name.ilike.%${req.query.search}%,email.ilike.%${req.query.search}%,phone.ilike.%${req.query.search}%,customer_id.ilike.%${req.query.search}%`);
    }

    if (req.query.customer_type) {
      query = query.eq('customer_type', req.query.customer_type);
    }

    if (req.query.is_active !== undefined) {
      query = query.eq('is_active', req.query.is_active === 'true');
    }

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data: customers, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: customers?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: customers || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single LPG customer
// @route   GET /api/customers/:id
// @access  Private
const getLPGCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: customer, error } = await supabase
      .from('lpg_customers')
      .select('*')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (error || !customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new LPG customer
// @route   POST /api/customers
// @access  Private
const createLPGCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Generate customer_id if not provided
    const customerId = req.body.customer_id || `CUST-${Date.now()}`;
    
    const customerData = {
      user_id: req.user.id,
      customer_id: customerId,
      name: req.body.name,
      email: req.body.email || null,
      phone: req.body.phone,
      address: req.body.address || null,
      city: req.body.city || null,
      state: req.body.state || null,
      postal_code: req.body.postal_code || null,
      customer_type: req.body.customer_type || 'residential',
      registration_date: req.body.registration_date || new Date().toISOString().split('T')[0],
      is_active: req.body.is_active !== undefined ? req.body.is_active : true,
      notes: req.body.notes || null
    };

    const { data: customer, error } = await supabase
      .from('lpg_customers')
      .insert([customerData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Customer created successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update LPG customer
// @route   PUT /api/customers/:id
// @access  Private
const updateLPGCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (req.body.email !== undefined) updateData.email = req.body.email;
    if (req.body.phone !== undefined) updateData.phone = req.body.phone;
    if (req.body.address !== undefined) updateData.address = req.body.address;
    if (req.body.city !== undefined) updateData.city = req.body.city;
    if (req.body.state !== undefined) updateData.state = req.body.state;
    if (req.body.postal_code !== undefined) updateData.postal_code = req.body.postal_code;
    if (req.body.customer_type !== undefined) updateData.customer_type = req.body.customer_type;
    if (req.body.is_active !== undefined) updateData.is_active = req.body.is_active;
    if (req.body.notes !== undefined) updateData.notes = req.body.notes;

    const { data: customer, error } = await supabase
      .from('lpg_customers')
      .update(updateData)
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      message: 'Customer updated successfully',
      data: customer
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete LPG customer
// @route   DELETE /api/customers/:id
// @access  Private
const deleteLPGCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data, error } = await supabase
      .from('lpg_customers')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    res.json({
      success: true,
      message: 'Customer deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Simplified methods - to be implemented later
const addPremises = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const updatePremises = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const removePremises = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const addRefillRecord = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getRefillHistory = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const updateCredit = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getCustomersDueForRefill = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getTopCustomers = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getCustomerAnalytics = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getConsumptionPattern = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

module.exports = {
  getLPGCustomers,
  getLPGCustomer,
  createLPGCustomer,
  updateLPGCustomer,
  deleteLPGCustomer,
  addPremises,
  updatePremises,
  removePremises,
  addRefillRecord,
  getRefillHistory,
  updateCredit,
  getCustomersDueForRefill,
  getTopCustomers,
  getCustomerAnalytics,
  getConsumptionPattern
};
