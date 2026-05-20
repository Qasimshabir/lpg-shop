const { getSupabaseClient } = require('../config/supabase');

// @desc    Create new LPG sale
// @route   POST /api/sales
// @access  Private
const createLPGSale = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { items, customer_id, payment_method, payment_status, delivery_status, delivery_address, notes } = req.body;
    
    // Validate items array
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Items array is required and must not be empty'
      });
    }
    
    // Validate item quantities and prices
    const validationErrors = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      
      if (!item.product_id) {
        validationErrors.push(`Item ${i + 1}: Product ID is required`);
      }
      
      if (!item.quantity || typeof item.quantity !== 'number') {
        validationErrors.push(`Item ${i + 1}: Valid quantity is required`);
      } else if (item.quantity <= 0) {
        validationErrors.push(`Item ${i + 1}: Quantity must be greater than 0`);
      } else if (!Number.isInteger(item.quantity)) {
        validationErrors.push(`Item ${i + 1}: Quantity must be a whole number`);
      }
      
      if (!item.unit_price || typeof item.unit_price !== 'number') {
        validationErrors.push(`Item ${i + 1}: Valid unit price is required`);
      } else if (item.unit_price <= 0) {
        validationErrors.push(`Item ${i + 1}: Unit price must be greater than 0`);
      }
    }
    
    if (validationErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validationErrors
      });
    }
    
    // Validate stock availability for all items before processing
    const stockErrors = [];
    for (let item of items) {
      const { data: product } = await supabase
        .from('lpg_products')
        .select('id, name, stock_quantity, cylinder_states, product_type')
        .eq('id', item.product_id)
        .single();
      
      if (!product) {
        stockErrors.push(`Product with ID ${item.product_id} not found`);
        continue;
      }
      
      let availableStock = 0;
      if (product.product_type === 'cylinder' && product.cylinder_states) {
        // For cylinders, check filled cylinders
        availableStock = product.cylinder_states.filled || 0;
      } else {
        // For accessories, check stock_quantity
        availableStock = product.stock_quantity || 0;
      }
      
      if (item.quantity > availableStock) {
        stockErrors.push(
          `Insufficient stock for "${product.name}". Requested: ${item.quantity}, Available: ${availableStock}`
        );
      }
    }
    
    // If there are stock errors, return them
    if (stockErrors.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Stock validation failed',
        errors: stockErrors
      });
    }
    
    // Calculate total amount
    let totalAmount = 0;
    for (let item of items) {
      totalAmount += (item.quantity * item.unit_price);
    }
    
    // Generate invoice number
    const invoiceNumber = `INV-${Date.now()}`;
    
    // Create sale
    const { data: sale, error: saleError } = await supabase
      .from('lpg_sales')
      .insert([{
        user_id: req.user.id,
        invoice_number: invoiceNumber,
        customer_id: customer_id || null,
        sale_date: new Date().toISOString(),
        total_amount: totalAmount,
        payment_method: payment_method || 'Cash',
        payment_status: payment_status || 'pending',
        delivery_status: delivery_status || 'pending',
        delivery_address: delivery_address || null,
        notes: notes || null
      }])
      .select()
      .single();
    
    if (saleError) throw saleError;
    
    // Create sale items
    const saleItems = items.map(item => ({
      sale_id: sale.id,
      product_id: item.product_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      subtotal: item.quantity * item.unit_price
    }));
    
    const { error: itemsError } = await supabase
      .from('sale_items')
      .insert(saleItems);
    
    if (itemsError) throw itemsError;
    
    // Update product stock and cylinder states
    for (let item of items) {
      const { data: product } = await supabase
        .from('lpg_products')
        .select('stock_quantity, cylinder_states, product_type')
        .eq('id', item.product_id)
        .single();
      
      if (product) {
        if (product.product_type === 'cylinder' && product.cylinder_states) {
          // Update cylinder states for cylinder products
          const states = product.cylinder_states;
          const newStates = {
            empty: states.empty || 0,
            filled: Math.max(0, (states.filled || 0) - item.quantity),
            sold: (states.sold || 0) + item.quantity
          };
          
          // Calculate new stock quantity (empty + filled)
          const newStockQuantity = newStates.empty + newStates.filled;
          
          await supabase
            .from('lpg_products')
            .update({ 
              stock_quantity: newStockQuantity,
              cylinder_states: newStates
            })
            .eq('id', item.product_id);
        } else {
          // For non-cylinder products, just update stock
          await supabase
            .from('lpg_products')
            .update({ stock_quantity: Math.max(0, product.stock_quantity - item.quantity) })
            .eq('id', item.product_id);
        }
      }
    }
    
    // Fetch complete sale with items
    const { data: completeSale } = await supabase
      .from('lpg_sales')
      .select(`
        *,
        lpg_customers(name, phone, email),
        sale_items(*, lpg_products(name, category))
      `)
      .eq('id', sale.id)
      .single();
    
    res.status(201).json({
      success: true,
      message: 'Sale created successfully',
      data: completeSale
    });
    
  } catch (error) {
    console.error('Sale creation error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to create sale'
    });
  }
};

// @desc    Get all LPG sales
// @route   GET /api/sales
// @access  Private
const getLPGSales = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    
    let query = supabase
      .from('lpg_sales')
      .select(`
        *,
        lpg_customers(name, phone, email),
        sale_items(*, lpg_products(name, category))
      `, { count: 'exact' })
      .eq('user_id', req.user.id);
    
    if (req.query.customer_id) {
      query = query.eq('customer_id', req.query.customer_id);
    }
    
    if (req.query.payment_status) {
      query = query.eq('payment_status', req.query.payment_status);
    }
    
    if (req.query.delivery_status) {
      query = query.eq('delivery_status', req.query.delivery_status);
    }
    
    if (req.query.start_date) {
      query = query.gte('sale_date', req.query.start_date);
    }
    
    if (req.query.end_date) {
      query = query.lte('sale_date', req.query.end_date);
    }
    
    query = query
      .order('sale_date', { ascending: false })
      .range(offset, offset + limit - 1);
    
    const { data: sales, error, count } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      count: sales?.length || 0,
      total: count || 0,
      page,
      pages: Math.ceil((count || 0) / limit),
      data: sales || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get sales report
// @route   GET /api/sales/report
// @access  Private
const getSalesReport = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    let query = supabase
      .from('lpg_sales')
      .select('total_amount, payment_method, payment_status')
      .eq('user_id', req.user.id);
    
    if (req.query.start_date) {
      query = query.gte('sale_date', req.query.start_date);
    }
    
    if (req.query.end_date) {
      query = query.lte('sale_date', req.query.end_date);
    }
    
    const { data: sales, error } = await query;
    
    if (error) throw error;
    
    // Calculate summary
    const summary = {
      totalSales: sales.length,
      totalRevenue: sales.reduce((sum, sale) => sum + parseFloat(sale.total_amount || 0), 0),
      avgSaleValue: sales.length > 0 ? sales.reduce((sum, sale) => sum + parseFloat(sale.total_amount || 0), 0) / sales.length : 0
    };
    
    // Group by payment method
    const byPaymentMethod = sales.reduce((acc, sale) => {
      const method = sale.payment_method || 'Unknown';
      if (!acc[method]) {
        acc[method] = { _id: method, count: 0, total: 0 };
      }
      acc[method].count++;
      acc[method].total += parseFloat(sale.total_amount || 0);
      return acc;
    }, {});
    
    // Group by status
    const byStatus = sales.reduce((acc, sale) => {
      const status = sale.payment_status || 'Unknown';
      if (!acc[status]) {
        acc[status] = { _id: status, count: 0, total: 0 };
      }
      acc[status].count++;
      acc[status].total += parseFloat(sale.total_amount || 0);
      return acc;
    }, {});
    
    res.json({
      success: true,
      data: {
        summary,
        byPaymentMethod: Object.values(byPaymentMethod),
        byStatus: Object.values(byStatus)
      }
    });
  } catch (error) {
    console.error('Sales report error:', error);
    next(error);
  }
};

// @desc    Delete LPG sale
// @route   DELETE /api/sales/:id
// @access  Private
const deleteLPGSale = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    const { id } = req.params;
    
    // First, verify the sale exists and belongs to the user
    const { data: sale, error: fetchError } = await supabase
      .from('lpg_sales')
      .select('id, user_id, invoice_number')
      .eq('id', id)
      .eq('user_id', req.user.id)
      .single();
    
    if (fetchError || !sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found or you do not have permission to delete it'
      });
    }
    
    // Delete sale items first (foreign key constraint)
    const { error: itemsDeleteError } = await supabase
      .from('sale_items')
      .delete()
      .eq('sale_id', id);
    
    if (itemsDeleteError) throw itemsDeleteError;
    
    // Delete the sale
    const { error: saleDeleteError } = await supabase
      .from('lpg_sales')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);
    
    if (saleDeleteError) throw saleDeleteError;
    
    res.json({
      success: true,
      message: `Sale ${sale.invoice_number} deleted successfully`
    });
    
  } catch (error) {
    console.error('Sale deletion error:', error);
    res.status(400).json({
      success: false,
      message: error.message || 'Failed to delete sale'
    });
  }
};

module.exports = {
  createLPGSale,
  getLPGSales,
  getSalesReport,
  deleteLPGSale
};
