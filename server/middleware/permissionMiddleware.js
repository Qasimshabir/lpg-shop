const { getSupabaseClient } = require('../config/supabase');

// Check if user has permission for a specific action on a resource
const checkPermission = (resource, action) => {
  return async (req, res, next) => {
    try {
      const supabase = getSupabaseClient();
      
      // Super admin and owner have all permissions
      if (req.user.role === 'super-admin' || req.user.role === 'owner' || req.user.role === 'admin') {
        return next();
      }
      
      // Check if user has role_id
      if (!req.user.role_id) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. No role assigned.'
        });
      }
      
      // Get role and check permissions
      const { data: role, error } = await supabase
        .from('roles')
        .select('permissions')
        .eq('id', req.user.role_id)
        .single();
      
      if (error || !role) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Invalid role.'
        });
      }
      
      // Parse permissions if it's a string
      const permissions = typeof role.permissions === 'string' 
        ? JSON.parse(role.permissions) 
        : role.permissions;
      
      // Check if role has 'all' permission
      if (permissions.includes('all')) {
        return next();
      }
      
      // Check if role has the required permission
      if (permissions.includes(action)) {
        return next();
      }
      
      return res.status(403).json({
        success: false,
        message: `Access denied. You don't have permission to ${action} ${resource}.`
      });
      
    } catch (error) {
      console.error('Permission check error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error checking permissions'
      });
    }
  };
};

// Check if user has any of the specified roles
const hasRole = (...roles) => {
  return async (req, res, next) => {
    try {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }
      
      // Get user's role name
      const supabase = getSupabaseClient();
      const { data: userRole } = await supabase
        .from('users')
        .select('roles(name)')
        .eq('id', req.user.id)
        .single();
      
      const roleName = userRole?.roles?.name;
      
      if (roles.includes(roleName)) {
        return next();
      }
      
      return res.status(403).json({
        success: false,
        message: 'Access denied. Insufficient role privileges.'
      });
    } catch (error) {
      console.error('Role check error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error checking role'
      });
    }
  };
};

// Check multiple permissions (user must have all)
const checkMultiplePermissions = (permissions) => {
  return async (req, res, next) => {
    try {
      const supabase = getSupabaseClient();
      
      // Super admin and owner have all permissions
      if (req.user.role === 'super-admin' || req.user.role === 'owner' || req.user.role === 'admin') {
        return next();
      }
      
      if (!req.user.role_id) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. No role assigned.'
        });
      }
      
      const { data: role, error } = await supabase
        .from('roles')
        .select('permissions')
        .eq('id', req.user.role_id)
        .single();
      
      if (error || !role) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Invalid role.'
        });
      }
      
      // Parse permissions if it's a string
      const rolePermissions = typeof role.permissions === 'string' 
        ? JSON.parse(role.permissions) 
        : role.permissions;
      
      // Check if role has 'all' permission
      if (rolePermissions.includes('all')) {
        return next();
      }
      
      // Check all required permissions
      for (const permission of permissions) {
        if (!rolePermissions.includes(permission)) {
          return res.status(403).json({
            success: false,
            message: `Access denied. Missing permission: ${permission}.`
          });
        }
      }
      
      return next();
      
    } catch (error) {
      console.error('Permission check error:', error);
      return res.status(500).json({
        success: false,
        message: 'Error checking permissions'
      });
    }
  };
};

module.exports = {
  checkPermission,
  hasRole,
  checkMultiplePermissions
};
