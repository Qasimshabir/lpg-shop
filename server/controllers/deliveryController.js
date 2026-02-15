const { getSupabaseClient } = require('../config/supabase');

// Simplified delivery controller - features to be implemented later
const addDeliveryPersonnel = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getDeliveryPersonnel = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const updateDeliveryPersonnel = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const assignDeliveries = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const createDeliveryRoute = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getDeliveryRoutes = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const startDeliveryRoute = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const completeDeliveryRoute = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const updateDeliveryProof = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getPendingDeliveries = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

module.exports = {
  addDeliveryPersonnel,
  getDeliveryPersonnel,
  updateDeliveryPersonnel,
  assignDeliveries,
  createDeliveryRoute,
  getDeliveryRoutes,
  startDeliveryRoute,
  completeDeliveryRoute,
  updateDeliveryProof,
  getPendingDeliveries
};
