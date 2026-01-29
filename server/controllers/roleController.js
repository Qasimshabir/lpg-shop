const Role = require('../models/Role');
const User = require('../models/User');

// @desc    Get all roles
// @route   GET /api/roles
// @access  Private (Admin only)
exports.getRoles = async (req, res, next) => {
  try {
    const { isActive } = req.query;
    
    const query = {};
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }
    
    const roles = await Role.find(query).sort({ name: 1 });
    
    res.json({
      success: true,
      count: roles.length,
      data: roles
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single role
// @route   GET /api/roles/:id
// @access  Private (Admin only)
exports.getRole = async (req, res, next) => {
  try {
    const role = await Role.findById(req.params.id);
    
    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }
    
    // Get users with this role
    const userCount = await User.countDocuments({ roleId: role._id });
    
    res.json({
      success: true,
      data: {
        ...role.toObject(),
        userCount
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new role
// @route   POST /api/roles
// @access  Private (Super Admin only)
exports.createRole = async (req, res, next) => {
  try {
    const role = await Role.create(req.body);
    
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
// @access  Private (Super Admin only)
exports.updateRole = async (req, res, next) => {
  try {
    const role = await Role.findById(req.params.id);
    
    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }
    
    // Prevent updating system roles
    if (role.isSystemRole) {
      return res.status(403).json({
        success: false,
        message: 'Cannot update system roles'
      });
    }
    
    const updatedRole = await Role.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    
    res.json({
      success: true,
      message: 'Role updated successfully',
      data: updatedRole
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete role
// @route   DELETE /api/roles/:id
// @access  Private (Super Admin only)
exports.deleteRole = async (req, res, next) => {
  try {
    const role = await Role.findById(req.params.id);
    
    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }
    
    // Prevent deleting system roles
    if (role.isSystemRole) {
      return res.status(403).json({
        success: false,
        message: 'Cannot delete system roles'
      });
    }
    
    // Check if any users have this role
    const userCount = await User.countDocuments({ roleId: role._id });
    if (userCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete role. ${userCount} user(s) are assigned to this role.`
      });
    }
    
    await role.deleteOne();
    
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
// @access  Private (Admin only)
exports.assignRole = async (req, res, next) => {
  try {
    const { roleId } = req.body;
    
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const role = await Role.findById(roleId);
    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }
    
    if (!role.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Cannot assign inactive role'
      });
    }
    
    user.roleId = roleId;
    user.role = role.name;
    user.permissions = role.permissions;
    await user.save();
    
    res.json({
      success: true,
      message: 'Role assigned successfully',
      data: {
        userId: user._id,
        userName: user.name,
        role: role.displayName
      }
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get role permissions
// @route   GET /api/roles/:id/permissions
// @access  Private
exports.getRolePermissions = async (req, res, next) => {
  try {
    const role = await Role.findById(req.params.id);
    
    if (!role) {
      return res.status(404).json({
        success: false,
        message: 'Role not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        role: role.name,
        displayName: role.displayName,
        permissions: role.permissions,
        permissionCount: role.permissionCount
      }
    });
  } catch (error) {
    next(error);
  }
};
