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

// @desc    Create new role
// @route   POST /api/roles
// @access  Private/Admin
const createRole = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const roleData = {
      name: req.body.name,
      description: req.body.description || null,
      permissions: JSON.stringify(req.body.permissions || [])
    };

    const { data: role, error } = await supabase
      .from('roles')
      .insert([roleData])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Role created successfully',
      data: role
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update role
// @route   PUT /api/roles/:id
// @access  Private/Admin
const updateRole = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const updateData = {};
    if (req.body.name !== undefined) updateData.name = req.body.name;
    if (req.body.description !== undefined) updateData.description = req.body.description;
    if (req.body.permissions !== undefined) updateData.permissions = JSON.stringify(req.body.permissions);

    const { data: role, error } = await supabase
      .from('roles')
      .update(updateData)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }

    res.json({
      success: true,
      message: 'Role updated successfully',
      data: role
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete role
// @route   DELETE /api/roles/:id
// @access  Private/Admin
const deleteRole = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    // Check if role is in use
    const { data: users } = await supabase
      .from('users')
      .select('id')
      .eq('role_id', req.params.id)
      .limit(1);

    if (users && users.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete role that is assigned to users'
      });
    }

    const { data, error } = await supabase
      .from('roles')
      .delete()
      .eq('id', req.params.id)
      .select();

    if (error) throw error;

    if (!data || data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }

    res.json({
      success: true,
      message: 'Role deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Assign role to user
// @route   PUT /api/roles/assign/:userId
// @access  Private/Admin
const assignRole = async (req, res, next) => {
  try {
    const supabase = getSupabaseClient();
    
    const { data: user, error } = await supabase
      .from('users')
      .update({ role_id: req.body.role_id })
      .eq('id', req.params.userId)
      .select('id, name, email, role_id')
      .single();

    if (error) throw error;

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      message: 'Role assigned successfully',
      data: user
    });
  } catch (error) {
    next(error);
  }
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
