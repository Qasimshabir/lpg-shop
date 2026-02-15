const { getSupabaseClient } = require('../config/supabase');
const logger = require('../config/logger');

// Get business insights and analytics
exports.getBusinessInsights = async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const userId = req.user.id;
    const { startDate, endDate } = req.query;

    // Date filters
    const start = startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
    const end = endDate || new Date().toISOString();

    // Get sales trends
    const { data: salesData, error: salesError } = await supabase
      .from('lpg_sales')
      .select('sale_date, total_amount, payment_status')
      .gte('sale_date', start)
      .lte('sale_date', end)
      .order('sale_date', { ascending: true });

    if (salesError) throw salesError;

    // Get top products
    const { data: topProducts, error: productsError } = await supabase
      .from('sale_items')
      .select(`
        product_id,
        quantity,
        subtotal,
        lpg_products (name, category)
      `)
      .gte('created_at', start)
      .lte('created_at', end);

    if (productsError) throw productsError;

    // Get customer analytics
    const { data: customers, error: customersError } = await supabase
      .from('lpg_customers')
      .select('id, customer_type, registration_date')
      .eq('user_id', userId);

    if (customersError) throw customersError;

    // Get cylinder refill trends
    const { data: refills, error: refillsError } = await supabase
      .from('cylinder_refill_history')
      .select('refill_date, quantity, amount')
      .gte('refill_date', start)
      .lte('refill_date', end);

    if (refillsError) throw refillsError;

    // Process sales trends by day
    const salesByDay = {};
    let totalRevenue = 0;
    let totalSales = 0;

    salesData.forEach(sale => {
      const date = sale.sale_date.split('T')[0];
      if (!salesByDay[date]) {
        salesByDay[date] = { date, revenue: 0, count: 0 };
      }
      salesByDay[date].revenue += parseFloat(sale.total_amount);
      salesByDay[date].count += 1;
      totalRevenue += parseFloat(sale.total_amount);
      totalSales += 1;
    });

    // Process top products
    const productStats = {};
    topProducts.forEach(item => {
      const productName = item.lpg_products?.name || 'Unknown';
      if (!productStats[productName]) {
        productStats[productName] = { name: productName, quantity: 0, revenue: 0 };
      }
      productStats[productName].quantity += item.quantity;
      productStats[productName].revenue += parseFloat(item.subtotal);
    });

    const topProductsList = Object.values(productStats)
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 5);

    // Customer insights
    const customersByType = customers.reduce((acc, customer) => {
      acc[customer.customer_type] = (acc[customer.customer_type] || 0) + 1;
      return acc;
    }, {});

    // Refill trends
    const refillsByMonth = {};
    refills.forEach(refill => {
      const month = refill.refill_date.substring(0, 7); // YYYY-MM
      if (!refillsByMonth[month]) {
        refillsByMonth[month] = { month, count: 0, revenue: 0 };
      }
      refillsByMonth[month].count += refill.quantity;
      refillsByMonth[month].revenue += parseFloat(refill.amount);
    });

    // Calculate growth rate
    const salesArray = Object.values(salesByDay);
    let growthRate = 0;
    if (salesArray.length >= 2) {
      const firstWeek = salesArray.slice(0, 7).reduce((sum, day) => sum + day.revenue, 0);
      const lastWeek = salesArray.slice(-7).reduce((sum, day) => sum + day.revenue, 0);
      growthRate = firstWeek > 0 ? ((lastWeek - firstWeek) / firstWeek * 100) : 0;
    }

    res.json({
      success: true,
      data: {
        summary: {
          totalRevenue,
          totalSales,
          averageSaleValue: totalSales > 0 ? totalRevenue / totalSales : 0,
          growthRate: growthRate.toFixed(2),
          totalCustomers: customers.length,
          totalRefills: refills.length,
        },
        salesTrends: Object.values(salesByDay),
        topProducts: topProductsList,
        customersByType,
        refillTrends: Object.values(refillsByMonth),
      },
    });
  } catch (error) {
    logger.error('Get business insights error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get business insights',
      error: error.message,
    });
  }
};

// Get revenue forecast
exports.getRevenueForecast = async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const { months = 3 } = req.query;

    // Get historical sales data (last 6 months)
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

    const { data: salesData, error } = await supabase
      .from('lpg_sales')
      .select('sale_date, total_amount')
      .gte('sale_date', sixMonthsAgo.toISOString())
      .order('sale_date', { ascending: true });

    if (error) throw error;

    // Group by month
    const monthlyRevenue = {};
    salesData.forEach(sale => {
      const month = sale.sale_date.substring(0, 7);
      monthlyRevenue[month] = (monthlyRevenue[month] || 0) + parseFloat(sale.total_amount);
    });

    const revenues = Object.values(monthlyRevenue);
    
    // Simple linear regression for forecast
    const avgRevenue = revenues.reduce((a, b) => a + b, 0) / revenues.length;
    const trend = revenues.length > 1 
      ? (revenues[revenues.length - 1] - revenues[0]) / revenues.length
      : 0;

    // Generate forecast
    const forecast = [];
    for (let i = 1; i <= parseInt(months); i++) {
      const forecastDate = new Date();
      forecastDate.setMonth(forecastDate.getMonth() + i);
      const forecastValue = avgRevenue + (trend * i);
      
      forecast.push({
        month: forecastDate.toISOString().substring(0, 7),
        forecastRevenue: Math.max(0, forecastValue),
        confidence: Math.max(0, 100 - (i * 10)), // Confidence decreases over time
      });
    }

    res.json({
      success: true,
      data: {
        historical: Object.entries(monthlyRevenue).map(([month, revenue]) => ({
          month,
          revenue,
        })),
        forecast,
        averageMonthlyRevenue: avgRevenue,
        trend: trend > 0 ? 'growing' : trend < 0 ? 'declining' : 'stable',
      },
    });
  } catch (error) {
    logger.error('Get revenue forecast error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get revenue forecast',
      error: error.message,
    });
  }
};

// Get customer lifetime value
exports.getCustomerLifetimeValue = async (req, res) => {
  try {
    const supabase = getSupabaseClient();
    const userId = req.user.id;

    const { data: customers, error: customersError } = await supabase
      .from('lpg_customers')
      .select(`
        id,
        name,
        registration_date,
        customer_type
      `)
      .eq('user_id', userId);

    if (customersError) throw customersError;

    // Get sales for each customer
    const customerValues = await Promise.all(
      customers.map(async (customer) => {
        const { data: sales, error: salesError } = await supabase
          .from('lpg_sales')
          .select('total_amount, sale_date')
          .eq('customer_id', customer.id);

        if (salesError) throw salesError;

        const totalSpent = sales.reduce((sum, sale) => sum + parseFloat(sale.total_amount), 0);
        const purchaseCount = sales.length;
        const avgPurchaseValue = purchaseCount > 0 ? totalSpent / purchaseCount : 0;

        // Calculate customer age in months
        const registrationDate = new Date(customer.registration_date);
        const now = new Date();
        const ageInMonths = (now.getFullYear() - registrationDate.getFullYear()) * 12 + 
                           (now.getMonth() - registrationDate.getMonth());

        const purchaseFrequency = ageInMonths > 0 ? purchaseCount / ageInMonths : 0;

        // Simple CLV calculation: avg purchase value * purchase frequency * 24 months
        const clv = avgPurchaseValue * purchaseFrequency * 24;

        return {
          customerId: customer.id,
          customerName: customer.name,
          customerType: customer.customer_type,
          totalSpent,
          purchaseCount,
          avgPurchaseValue,
          purchaseFrequency,
          lifetimeValue: clv,
          ageInMonths,
        };
      })
    );

    // Sort by lifetime value
    customerValues.sort((a, b) => b.lifetimeValue - a.lifetimeValue);

    res.json({
      success: true,
      data: {
        topCustomers: customerValues.slice(0, 10),
        averageLifetimeValue: customerValues.reduce((sum, c) => sum + c.lifetimeValue, 0) / customerValues.length,
        totalCustomers: customerValues.length,
      },
    });
  } catch (error) {
    logger.error('Get customer lifetime value error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get customer lifetime value',
      error: error.message,
    });
  }
};
