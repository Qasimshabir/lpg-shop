const mongoose = require('mongoose');

const roleSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Role name is required'],
    unique: true,
    enum: ['super-admin', 'admin', 'manager', 'sales-person', 'delivery-person', 'inventory-manager'],
    lowercase: true
  },
  displayName: {
    type: String,
    required: [true, 'Display name is required']
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    maxlength: [500, 'Description cannot be more than 500 characters']
  },
  permissions: [{
    resource: {
      type: String,
      required: true
    },
    actions: [{
      type: String,
      enum: ['create', 'read', 'update', 'delete', 'export', 'approve']
    }]
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  isSystemRole: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes
roleSchema.index({ name: 1 });
roleSchema.index({ isActive: 1 });

// Method to check if role has permission
roleSchema.methods.hasPermission = function(resource, action) {
  const permission = this.permissions.find(p => p.resource === resource);
  if (!permission) return false;
  return permission.actions.includes(action);
};

// Method to get all permissions for a resource
roleSchema.methods.getResourcePermissions = function(resource) {
  const permission = this.permissions.find(p => p.resource === resource);
  return permission ? permission.actions : [];
};

// Static method to get role by name
roleSchema.statics.findByName = function(name) {
  return this.findOne({ name: name.toLowerCase(), isActive: true });
};

// Virtual for permission count
roleSchema.virtual('permissionCount').get(function() {
  return this.permissions.reduce((sum, p) => sum + p.actions.length, 0);
});

module.exports = mongoose.model('Role', roleSchema);
