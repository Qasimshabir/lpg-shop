const express = require('express');
const {
  getLPGProducts,
  getLPGProduct,
  createLPGProduct,
  updateLPGProduct,
  deleteLPGProduct,
  updateCylinderState,
  exchangeCylinder,
  getLowStockProducts,
  getProductsByCategory,
  getCylinderSummary,
  getProductsDueForInspection
} = require('../controllers/lpgProductController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// All routes are protected
router.use(protect);

// Product CRUD routes
router.route('/')
  .get(getLPGProducts)
  .post(createLPGProduct);

router.route('/:id')
  .get(getLPGProduct)
  .put(updateLPGProduct)
  .delete(deleteLPGProduct);

// Cylinder-specific routes
router.put('/:id/cylinder-state', updateCylinderState);
router.put('/:id/exchange', exchangeCylinder);

// Inventory management routes
router.get('/low-stock', getLowStockProducts);
router.get('/category/:category', getProductsByCategory);
router.get('/cylinder-summary', getCylinderSummary);
router.get('/inspection-due', getProductsDueForInspection);

module.exports = router;