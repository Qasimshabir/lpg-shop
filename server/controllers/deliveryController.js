const { getSupabaseClient } = require('../config/supabase');

// @desc    Add delivery personnel
// @route   POST /api/delivery/personnel
// @access  Private
const addDeliveryPersonnel = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const personnelData = {
      user_id: req.user.id,
      vehicle_number: req.body.vehicle_number,
      license_number: req.body.license_number,
      phone: req.body.phone,
      is_available: req.body.is_available !== undefined ? req.body.is_available : true
    };

    const { data: personnel, error } = await supabase
      .from('delivery_personnel')
      .insert([personnelData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Delivery personnel added successfully',
      data: personnel
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get delivery personnel
// @route   GET /api/delivery/personnel
// @access  Private
const getDeliveryPersonnel = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('delivery_personnel')
      .select('*')
      .eq('user_id', req.user.id);

    if (req.query.is_available !== undefined) {
      query = query.eq('is_available', req.query.is_available === 'true');
    }

    query = query.order('created_at', { ascending: false });

    const { data: personnel, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: personnel?.length || 0,
      data: personnel || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update delivery personnel
// @route   PUT /api/delivery/personnel/:id
// @access  Private
const updateDeliveryPersonnel = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    if (req.body.vehicle_number !== undefined) updateData.vehicle_number = req.body.vehicle_number;
    if (req.body.license_number !== undefined) updateData.license_number = req.body.license_number;
    if (req.body.phone !== undefined) updateData.phone = req.body.phone;
    if (req.body.is_available !== undefined) updateData.is_available = req.body.is_available;

    const { data: personnel, error } = await supabase
      .from('delivery_personnel')
      .update(updateData)
      .eq('id', req.params.id)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    if (!personnel) {
      return res.status(404).json({
        success: false,
        message: 'Delivery personnel not found'
      });
    }

    res.json({
      success: true,
      message: 'Delivery personnel updated successfully',
      data: personnel
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Assign deliveries to personnel
// @route   POST /api/delivery/assign
// @access  Private
const assignDeliveries = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const routeData = {
      date: req.body.date || new Date().toISOString().split('T')[0],
      personnel_id: req.body.personnel_id,
      status: 'planned'
    };

    const { data: route, error } = await supabase
      .from('delivery_routes')
      .insert([routeData])
      .select()
      .single();

    if (error) throw error;

    // Update sales with delivery route
    if (req.body.sale_ids && req.body.sale_ids.length > 0) {
      const { error: updateError } = await supabase
        .from('lpg_sales')
        .update({ delivery_status: 'assigned' })
        .in('id', req.body.sale_ids);

      if (updateError) throw updateError;
    }

    res.status(201).json({
      success: true,
      message: 'Deliveries assigned successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get delivery routes
// @route   GET /api/delivery/routes
// @access  Private
const getDeliveryRoutes = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('delivery_routes')
      .select('*, delivery_personnel(vehicle_number, phone)')
      .order('date', { ascending: false });

    if (req.query.status) {
      query = query.eq('status', req.query.status);
    }

    if (req.query.date) {
      query = query.eq('date', req.query.date);
    }

    if (req.query.personnel_id) {
      query = query.eq('personnel_id', req.query.personnel_id);
    }

    const { data: routes, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: routes?.length || 0,
      data: routes || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Start delivery route
// @route   PUT /api/delivery/routes/:id/start
// @access  Private
const startDeliveryRoute = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: route, error } = await supabase
      .from('delivery_routes')
      .update({ status: 'in_progress' })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Delivery route not found'
      });
    }

    res.json({
      success: true,
      message: 'Delivery route started successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Complete delivery route
// @route   PUT /api/delivery/routes/:id/complete
// @access  Private
const completeDeliveryRoute = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: route, error } = await supabase
      .from('delivery_routes')
      .update({ status: 'completed' })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!route) {
      return res.status(404).json({
        success: false,
        message: 'Delivery route not found'
      });
    }

    res.json({
      success: true,
      message: 'Delivery route completed successfully',
      data: route
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update delivery proof
// @route   PUT /api/delivery/:saleId/proof
// @access  Private
const updateDeliveryProof = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: sale, error } = await supabase
      .from('lpg_sales')
      .update({
        delivery_status: 'delivered',
        delivery_address: req.body.delivery_address || null,
        notes: req.body.notes || null
      })
      .eq('id', req.params.saleId)
      .eq('user_id', req.user.id)
      .select()
      .single();

    if (error) throw error;

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }

    res.json({
      success: true,
      message: 'Delivery proof updated successfully',
      data: sale
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get pending deliveries
// @route   GET /api/delivery/pending
// @access  Private
const getPendingDeliveries = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: sales, error } = await supabase
      .from('lpg_sales')
      .select('*, lpg_customers(name, phone, address)')
      .eq('user_id', req.user.id)
      .in('delivery_status', ['pending', 'assigned'])
      .order('sale_date', { ascending: true });

    if (error) throw error;

    res.json({
      success: true,
      count: sales?.length || 0,
      data: sales || []
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  addDeliveryPersonnel,
  getDeliveryPersonnel,
  updateDeliveryPersonnel,
  assignDeliveries,
  getDeliveryRoutes,
  startDeliveryRoute,
  completeDeliveryRoute,
  updateDeliveryProof,
  getPendingDeliveries
};
