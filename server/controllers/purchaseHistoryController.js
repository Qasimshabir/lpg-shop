const { supabase } = require('../config/supabase');
const logger = require('../config/logger');

/**
 * Get complete purchase history for a customer
 */
exports.getCustomerPurchaseHistory = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { limit = 50, offset = 0, startDate, endDate } = req.query;

    let query = supabase
      .from('lpg_sales')
      .select(`
        id,
        invoice_number,
        sale_date,
        total_amount,
        payment_method,
        payment_status,
        delivery_status,
        delivery_address,
        notes,
        sale_items (
          id,
          quantity,
          unit_price,
          subtotal,
          lpg_products (
            id,
            name,
            category,
            image_url,
            brands (
              title
            )
          )
        )
      `)
      .eq('customer_id', customerId)
      .order('sale_date', { ascending: false })
      .range(offset, offset + limit - 1);

    // Add date range filter if provided
    if (startDate) {
      query = query.gte('sale_date', startDate);
    }
    if (endDate) {
      query = query.lte('sale_date', endDate);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    // Get total count for pagination
    const { count: totalCount } = await supabase
      .from('lpg_sales')
      .select('*', { count: 'exact', head: true })
      .eq('customer_id', customerId);

    res.status(200).json({
      success: true,
      data: {
        purchases: data,
        pagination: {
          total: totalCount,
          limit: parseInt(limit),
          offset: parseInt(offset),
          hasMore: totalCount > offset + limit
        }
      }
    });
  } catch (error) {
    logger.error('Error fetching purchase history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch purchase history',
      error: error.message
    });
  }
};

/**
 * Get purchase summary for a customer
 */
exports.getCustomerPurchaseSummary = async (req, res) => {
  try {
    const { customerId } = req.params;

    const { data, error } = await supabase
      .from('customer_purchase_summary')
      .select('*')
      .eq('customer_id', customerId)
      .single();

    if (error) throw error;

    res.status(200).json({
      success: true,
      data
    });
  } catch (error) {
    logger.error('Error fetching purchase summary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch purchase summary',
      error: error.message
    });
  }
};

/**
 * Get detailed information for a specific sale
 */
exports.getSaleDetails = async (req, res) => {
  try {
    const { saleId } = req.params;

    const { data, error } = await supabase
      .rpc('get_sale_details', { p_sale_id: saleId });

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found'
      });
    }

    // Group the data into a structured format
    const saleInfo = {
      id: data[0].sale_id,
      invoiceNumber: data[0].invoice_number,
      saleDate: data[0].sale_date,
      customer: {
        name: data[0].customer_name,
        phone: data[0].customer_phone
      },
      totalAmount: data[0].total_amount,
      paymentMethod: data[0].payment_method,
      paymentStatus: data[0].payment_status,
      deliveryStatus: data[0].delivery_status,
      deliveryAddress: data[0].delivery_address,
      items: data.map(item => ({
        productId: item.product_id,
        productName: item.product_name,
        brandName: item.brand_name,
        quantity: item.quantity,
        unitPrice: item.unit_price,
        subtotal: item.subtotal
      }))
    };

    res.status(200).json({
      success: true,
      data: saleInfo
    });
  } catch (error) {
    logger.error('Error fetching sale details:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch sale details',
      error: error.message
    });
  }
};

/**
 * Get customer's product preferences based on purchase history
 */
exports.getCustomerProductPreferences = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { limit = 10 } = req.query;

    const { data, error } = await supabase
      .rpc('get_customer_product_preferences', {
        p_customer_id: customerId,
        p_limit: parseInt(limit)
      });

    if (error) throw error;

    res.status(200).json({
      success: true,
      data
    });
  } catch (error) {
    logger.error('Error fetching product preferences:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch product preferences',
      error: error.message
    });
  }
};

/**
 * Get purchase history by date range
 */
exports.getPurchaseHistoryByDateRange = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date are required'
      });
    }

    const { data, error } = await supabase
      .rpc('get_purchase_history_by_date', {
        p_customer_id: customerId,
        p_start_date: startDate,
        p_end_date: endDate
      });

    if (error) throw error;

    res.status(200).json({
      success: true,
      data
    });
  } catch (error) {
    logger.error('Error fetching purchase history by date:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch purchase history',
      error: error.message
    });
  }
};

/**
 * Calculate customer lifetime value
 */
exports.getCustomerLifetimeValue = async (req, res) => {
  try {
    const { customerId } = req.params;

    const { data, error } = await supabase
      .rpc('calculate_customer_ltv', { p_customer_id: customerId });

    if (error) throw error;

    res.status(200).json({
      success: true,
      data: data[0] || null
    });
  } catch (error) {
    logger.error('Error calculating customer LTV:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to calculate customer lifetime value',
      error: error.message
    });
  }
};

/**
 * Get customer loyalty metrics
 */
exports.getCustomerLoyaltyMetrics = async (req, res) => {
  try {
    const { customerId } = req.params;

    const { data, error } = await supabase
      .from('customer_loyalty_metrics')
      .select('*')
      .eq('customer_id', customerId)
      .single();

    if (error) throw error;

    res.status(200).json({
      success: true,
      data
    });
  } catch (error) {
    logger.error('Error fetching loyalty metrics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch loyalty metrics',
      error: error.message
    });
  }
};

/**
 * Get monthly purchase trends for a customer
 */
exports.getMonthlyPurchaseTrends = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { months = 12 } = req.query;

    const startDate = new Date();
    startDate.setMonth(startDate.getMonth() - parseInt(months));

    const { data, error } = await supabase
      .from('lpg_sales')
      .select('sale_date, total_amount')
      .eq('customer_id', customerId)
      .gte('sale_date', startDate.toISOString())
      .order('sale_date', { ascending: true });

    if (error) throw error;

    // Group by month
    const monthlyData = {};
    data.forEach(sale => {
      const month = new Date(sale.sale_date).toISOString().slice(0, 7); // YYYY-MM
      if (!monthlyData[month]) {
        monthlyData[month] = {
          month,
          totalAmount: 0,
          orderCount: 0
        };
      }
      monthlyData[month].totalAmount += parseFloat(sale.total_amount);
      monthlyData[month].orderCount += 1;
    });

    const trends = Object.values(monthlyData).sort((a, b) => 
      a.month.localeCompare(b.month)
    );

    res.status(200).json({
      success: true,
      data: trends
    });
  } catch (error) {
    logger.error('Error fetching monthly trends:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch monthly purchase trends',
      error: error.message
    });
  }
};

/**
 * Search purchase history
 */
exports.searchPurchaseHistory = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { query, limit = 20 } = req.query;

    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    const { data, error } = await supabase
      .from('lpg_sales')
      .select(`
        id,
        invoice_number,
        sale_date,
        total_amount,
        payment_status,
        sale_items (
          lpg_products (
            name
          )
        )
      `)
      .eq('customer_id', customerId)
      .or(`invoice_number.ilike.%${query}%,notes.ilike.%${query}%`)
      .order('sale_date', { ascending: false })
      .limit(limit);

    if (error) throw error;

    res.status(200).json({
      success: true,
      data
    });
  } catch (error) {
    logger.error('Error searching purchase history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search purchase history',
      error: error.message
    });
  }
};

/**
 * Export purchase history to CSV
 */
exports.exportPurchaseHistory = async (req, res) => {
  try {
    const { customerId } = req.params;
    const { startDate, endDate } = req.query;

    let query = supabase
      .from('lpg_sales')
      .select(`
        invoice_number,
        sale_date,
        total_amount,
        payment_method,
        payment_status,
        delivery_status
      `)
      .eq('customer_id', customerId)
      .order('sale_date', { ascending: false });

    if (startDate) query = query.gte('sale_date', startDate);
    if (endDate) query = query.lte('sale_date', endDate);

    const { data, error } = await query;

    if (error) throw error;

    // Convert to CSV
    const headers = ['Invoice Number', 'Date', 'Amount', 'Payment Method', 'Payment Status', 'Delivery Status'];
    const csvRows = [headers.join(',')];

    data.forEach(row => {
      const values = [
        row.invoice_number,
        new Date(row.sale_date).toLocaleDateString(),
        row.total_amount,
        row.payment_method,
        row.payment_status,
        row.delivery_status
      ];
      csvRows.push(values.join(','));
    });

    const csv = csvRows.join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename=purchase-history-${customerId}.csv`);
    res.status(200).send(csv);
  } catch (error) {
    logger.error('Error exporting purchase history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to export purchase history',
      error: error.message
    });
  }
};
