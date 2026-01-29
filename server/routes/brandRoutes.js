const express = require('express');
const router = express.Router();
const { getBrands, createBrand, updateBrand, deleteBrand } = require('../controllers/brandController');
const { protect } = require('../middleware/authMiddleware');

// List all brands for the current user
router.get('/', protect, getBrands);

// Create a new brand for the current user
router.post('/', protect, createBrand);

// Update a brand for the current user
router.put('/:id', protect, updateBrand);

// Delete a brand for the current user
router.delete('/:id', protect, deleteBrand);

module.exports = router;
