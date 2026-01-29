const Role = require('../models/Role');

// Check if user has permission for a specific action on a resource
const checkPermission = (resource, action) => {
  return async (req, res, next) => {
    try {
      // Super admin and owner have all permissions
      if (req.user.role === 'super-admin' || req.user.role === 'owner') {
        return next();
      }
      
      // Check if user has roleId
      if (!req.user.roleId) {
        // Check inline permissions
        if (req.user.permissions && req.user.permissions.length > 0) {
          const permission = req.user.permissions.find(p => p.resource === resource);
          if (permission && permission.actions.includes(action)) {
            return next();
          }
        }
        
        return res.status(403).json({
          success: false,
          message: 'Access denied. No role assigned.'
        });
      }
      
      // Get role and check permissions
      const role = await Role.findById(req.user.roleId);
      
      if (!role || !role.isActive) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Invalid or inactive role.'
        });
      }
      
      // Check if role has the required permission
      if (role.hasPermission(resource, action)) {
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
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }
    
    if (roles.includes(req.user.role)) {
      return next();
    }
    
    return res.status(403).json({
      success: false,
      message: 'Access denied. Insufficient role privileges.'
    });
  };
};

// Check multiple permissions (user must have all)
const checkMultiplePermissions = (permissions) => {
  return async (req, res, next) => {
    try {
      // Super admin and owner have all permissions
      if (req.user.role === 'super-admin' || req.user.role === 'owner') {
        return next();
      }
      
      if (!req.user.roleId) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. No role assigned.'
        });
      }
      
      const role = await Role.findById(req.user.roleId);
      
      if (!role || !role.isActive) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. Invalid or inactive role.'
        });
      }
      
      // Check all permissions
      for (const { resource, action } of permissions) {
        if (!role.hasPermission(resource, action)) {
          return res.status(403).json({
            success: false,
            message: `Access denied. Missing permission: ${action} ${resource}.`
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
