const { getSupabaseClient } = require('../config/supabase');

// @desc    Get all available categories
// @route   GET /api/categories
// @access  Private
const getCategories = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Get distinct categories from products
    const { data: products, error } = await supabase
      .from('lpg_products')
      .select('category')
      .eq('user_id', req.user.id)
      .eq('is_active', true);

    if (error) throw error;

    // Get unique categories
    const categories = [...new Set(products.map(p => p.category).filter(Boolean))];

    res.json({
      success: true,
      count: categories.length,
      data: categories
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get categories with product count
// @route   GET /api/categories/stats
// @access  Private
const getCategoriesWithStats = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: products, error } = await supabase
      .from('lpg_products')
      .select('category')
      .eq('user_id', req.user.id)
      .eq('is_active', true);

    if (error) throw error;

    // Count products by category
    const categoryStats = products.reduce((acc, product) => {
      const category = product.category || 'Uncategorized';
      acc[category] = (acc[category] || 0) + 1;
      return acc;
    }, {});

    const stats = Object.entries(categoryStats).map(([category, count]) => ({
      _id: category,
      count
    }));

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCategories,
  getCategoriesWithStats
};
