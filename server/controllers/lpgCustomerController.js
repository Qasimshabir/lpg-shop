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

    // Get customer premises
    const { data: premises } = await supabase
      .from('customer_premises')
      .select('*')
      .eq('customer_id', req.params.id);

    // Get refill history
    const { data: refills } = await supabase
      .from('cylinder_refill_history')
      .select('*')
      .eq('customer_id', req.params.id)
      .order('refill_date', { ascending: false })
      .limit(10);

    res.json({
      success: true,
      data: {
        ...customer,
        premises: premises || [],
        recent_refills: refills || []
      }
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
// @desc    Update LPG customer
// @route   PUT /api/customers/:id
// @access  Private
const updateLPGCustomer = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    
    // Basic fields
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (req.body.email !== undefined) updateData.email = req.body.email;
    if (req.body.phone !== undefined) updateData.phone = req.body.phone;
    if (req.body.alternatePhone !== undefined) updateData.alternate_phone = req.body.alternatePhone;
    if (req.body.address !== undefined) updateData.address = req.body.address;
    if (req.body.city !== undefined) updateData.city = req.body.city;
    if (req.body.state !== undefined) updateData.state = req.body.state;
    if (req.body.postal_code !== undefined) updateData.postal_code = req.body.postal_code;
    if (req.body.postalCode !== undefined) updateData.postal_code = req.body.postalCode;
    
    // Customer type fields
    if (req.body.customer_type !== undefined) updateData.customer_type = req.body.customer_type;
    if (req.body.customerType !== undefined) updateData.customer_type = req.body.customerType;
    if (req.body.businessName !== undefined) updateData.business_name = req.body.businessName;
    if (req.body.gstNumber !== undefined) updateData.gst_number = req.body.gstNumber;
    
    // Credit and preferences
    if (req.body.creditLimit !== undefined) updateData.credit_limit = req.body.creditLimit;
    if (req.body.preferredCylinderCapacity !== undefined) updateData.preferred_cylinder_capacity = req.body.preferredCylinderCapacity;
    
    // Status and notes
    if (req.body.is_active !== undefined) updateData.is_active = req.body.is_active;
    if (req.body.isActive !== undefined) updateData.is_active = req.body.isActive;
    if (req.body.notes !== undefined) updateData.notes = req.body.notes;

    updateData.updated_at = new Date().toISOString();

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

// @desc    Add premises to customer
// @route   POST /api/customers/:id/premises
// @access  Private
const addPremises = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Verify customer exists and belongs to user
    const { data: customer } = await supabase
      .from('lpg_customers')
      .select('id')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    const premisesData = {
      customer_id: req.params.id,
      premises_type: req.body.premises_type || 'Residential',
      address: req.body.address,
      city: req.body.city,
      state: req.body.state,
      postal_code: req.body.postal_code,
      is_primary: req.body.is_primary || false
    };

    const { data: premises, error } = await supabase
      .from('customer_premises')
      .insert([premisesData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Premises added successfully',
      data: premises
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update premises
// @route   PUT /api/customers/:id/premises/:premisesId
// @access  Private
const updatePremises = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    if (req.body.premises_type !== undefined) updateData.premises_type = req.body.premises_type;
    if (req.body.address !== undefined) updateData.address = req.body.address;
    if (req.body.city !== undefined) updateData.city = req.body.city;
    if (req.body.state !== undefined) updateData.state = req.body.state;
    if (req.body.postal_code !== undefined) updateData.postal_code = req.body.postal_code;
    if (req.body.is_primary !== undefined) updateData.is_primary = req.body.is_primary;

    const { data: premises, error } = await supabase
      .from('customer_premises')
      .update(updateData)
      .eq('id', req.params.premisesId)
      .eq('customer_id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!premises) {
      return res.status(404).json({
        success: false,
        message: 'Premises not found'
      });
    }

    res.json({
      success: true,
      message: 'Premises updated successfully',
      data: premises
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove premises
// @route   DELETE /api/customers/:id/premises/:premisesId
// @access  Private
const removePremises = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data, error } = await supabase
      .from('customer_premises')
      .delete()
      .eq('id', req.params.premisesId)
      .eq('customer_id', req.params.id)
      .select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Premises not found'
      });
    }

    res.json({
      success: true,
      message: 'Premises removed successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add refill record
// @route   POST /api/customers/:id/refill
// @access  Private
const addRefillRecord = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const refillData = {
      customer_id: req.params.id,
      cylinder_id: req.body.cylinder_id || null,
      refill_date: req.body.refill_date || new Date().toISOString().split('T')[0],
      quantity: req.body.quantity,
      amount: req.body.amount
    };

    const { data: refill, error } = await supabase
      .from('cylinder_refill_history')
      .insert([refillData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Refill record added successfully',
      data: refill
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer refill history
// @route   GET /api/customers/:id/refill-history
// @access  Private
const getRefillHistory = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const { data: refills, error, count } = await supabase
      .from('cylinder_refill_history')
      .select('*', { count: 'exact' })
      .eq('customer_id', req.params.id)
      .order('refill_date', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.json({
      success: true,
      count: refills?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: refills || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update customer credit
// @route   PUT /api/customers/:id/credit
// @access  Private
const updateCredit = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { amount, operation = 'add', notes } = req.body;

    // Get current customer
    const { data: customer, error: fetchError } = await supabase
      .from('lpg_customers')
      .select('notes')
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .single();

    if (fetchError || !customer) {
      return res.status(404).json({
        success: false,
        message: 'Customer not found'
      });
    }

    // Update notes with credit information
    const creditNote = `Credit ${operation}: ${amount}. ${notes || ''}`;
    const updatedNotes = customer.notes 
      ? `${customer.notes}\n${creditNote}` 
      : creditNote;

    const { data: updated, error } = await supabase
      .from('lpg_customers')
      .update({ notes: updatedNotes })
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Credit information updated successfully',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customers due for refill
// @route   GET /api/customers/due-refill
// @access  Private
const getCustomersDueForRefill = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const daysAhead = parseInt(req.query.days) || 7;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30); // Customers who haven't refilled in 30 days

    const { data: refills, error } = await supabase
      .from('cylinder_refill_history')
      .select('customer_id, refill_date')
      .gte('refill_date', cutoffDate.toISOString().split('T')[0])
      .order('refill_date', { ascending: false });

    if (error) throw error;

    // Get unique customer IDs
    const recentCustomerIds = [...new Set(refills.map(r => r.customer_id))];

    // Get all customers not in recent list
    const { data: customers, error: custError } = await supabase
      .from('lpg_customers')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('is_active', true)
      .not('id', 'in', `(${recentCustomerIds.join(',')})`);

    if (custError) throw custError;

    res.json({
      success: true,
      count: customers?.length || 0,
      data: customers || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get top customers by spending
// @route   GET /api/customers/top-customers
// @access  Private
const getTopCustomers = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const limit = parseInt(req.query.limit) || 10;

    const { data: sales, error } = await supabase
      .from('lpg_sales')
      .select('customer_id, total_amount')
      .eq('user_id', req.user.id)
      .not('customer_id', 'is', null);

    if (error) throw error;

    // Aggregate by customer
    const customerTotals = sales.reduce((acc, sale) => {
      if (!acc[sale.customer_id]) {
        acc[sale.customer_id] = 0;
      }
      acc[sale.customer_id] += parseFloat(sale.total_amount);
      return acc;
    }, {});

    // Sort and get top customers
    const topCustomerIds = Object.entries(customerTotals)
      .sort((a, b) => b[1] - a[1])
      .slice(0, limit)
      .map(([id]) => id);

    if (topCustomerIds.length === 0) {
      return res.json({
        success: true,
        count: 0,
        data: []
      });
    }

    const { data: customers, error: custError } = await supabase
      .from('lpg_customers')
      .select('*')
      .in('id', topCustomerIds);

    if (custError) throw custError;

    // Add total spent to each customer
    const customersWithTotals = customers.map(customer => ({
      ...customer,
      total_spent: customerTotals[customer.id]
    }));

    res.json({
      success: true,
      count: customersWithTotals.length,
      data: customersWithTotals
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer analytics
// @route   GET /api/customers/analytics
// @access  Private
const getCustomerAnalytics = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: customers, error } = await supabase
      .from('lpg_customers')
      .select('customer_type, is_active')
      .eq('user_id', req.user.id);

    if (error) throw error;

    const analytics = {
      totalCustomers: customers.length,
      activeCustomers: customers.filter(c => c.is_active).length,
      inactiveCustomers: customers.filter(c => !c.is_active).length,
      byType: customers.reduce((acc, c) => {
        acc[c.customer_type] = (acc[c.customer_type] || 0) + 1;
        return acc;
      }, {})
    };

    res.json({
      success: true,
      data: analytics
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get customer consumption pattern
// @route   GET /api/customers/:id/consumption-pattern
// @access  Private
const getConsumptionPattern = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: refills, error } = await supabase
      .from('cylinder_refill_history')
      .select('refill_date, quantity, amount')
      .eq('customer_id', req.params.id)
      .order('refill_date', { ascending: false })
      .limit(12);

    if (error) throw error;

    // Group by month
    const monthlyData = refills.reduce((acc, refill) => {
      const month = refill.refill_date.substring(0, 7); // YYYY-MM
      if (!acc[month]) {
        acc[month] = { month, totalQuantity: 0, totalAmount: 0, count: 0 };
      }
      acc[month].totalQuantity += parseFloat(refill.quantity);
      acc[month].totalAmount += parseFloat(refill.amount);
      acc[month].count += 1;
      return acc;
    }, {});

    res.json({
      success: true,
      data: Object.values(monthlyData).reverse()
    });
  } catch (error) {
    next(error);
  }
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
