const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { hasRole } = require('../middleware/permissionMiddleware');
const {
  getRoles,
  getRole,
  createRole,
  updateRole,
  deleteRole,
  assignRole,
  getRolePermissions
} = require('../controllers/roleController');

// All routes require authentication
router.use(protect);

// Role CRUD (Admin and Super Admin only)
router.route('/')
  .get(hasRole('super-admin', 'admin', 'owner'), getRoles)
  .post(hasRole('super-admin'), createRole);

router.route('/:id')
  .get(hasRole('super-admin', 'admin', 'owner'), getRole)
  .put(hasRole('super-admin'), updateRole)
  .delete(hasRole('super-admin'), deleteRole);

// Role assignment
router.put('/assign/:userId', hasRole('super-admin', 'admin', 'owner'), assignRole);

// Get role permissions
router.get('/:id/permissions', getRolePermissions);

module.exports = router;
