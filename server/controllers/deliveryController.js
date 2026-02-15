const { getSupabaseClient } = require('../config/supabase');

// Simplified delivery controller - features to be implemented later
const addDeliveryPersonnel = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getDeliveryPersonnel = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const createDeliveryRoute = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getDeliveryRoutes = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

module.exports = {
  addDeliveryPersonnel,
  getDeliveryPersonnel,
  createDeliveryRoute,
  getDeliveryRoutes
};
