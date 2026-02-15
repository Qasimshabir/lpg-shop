const { getSupabaseClient } = require('../config/supabase');

// @desc    Get all roles
// @route   GET /api/roles
// @access  Private/Admin
const getRoles = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: roles, error } = await supabase
      .from('roles')
      .select('*')
      .order('name', { ascending: true });

    if (error) throw error;

    res.json({
      success: true,
      count: roles?.length || 0,
      data: roles || []
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single role
// @route   GET /api/roles/:id
// @access  Private/Admin
const getRole = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: role, error } = await supabase
      .from('roles')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }

    res.json({
      success: true,
      data: role
    });
  } catch (error) {
    next(error);
  }
};

// Stub functions for features not yet implemented
const createRole = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const updateRole = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const deleteRole = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const assignRole = async (req, res, next) => {
  res.status(501).json({ success: false, message: 'Feature not yet implemented' });
};

const getRolePermissions = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: role, error } = await supabase
      .from('roles')
      .select('permissions')
      .eq('id', req.params.id)
      .single();

    if (error || !role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }

    res.json({
      success: true,
      data: role.permissions
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getRoles,
  getRole,
  createRole,
  updateRole,
  deleteRole,
  assignRole,
  getRolePermissions
};
