const express = require('express');
const router = express.Router();
const { getImageById } = require('../utils/fileStorage');

// Get image by ID
router.get('/:id', async (req, res) => {
  try {
    const image = await getImageById(req.params.id);
    
    if (!image) {
      return res.status(404).json({
        success: false,
        message: 'Image not found'
      });
    }

    // Set appropriate headers
    res.set('Content-Type', image.mimeType);
    res.set('Content-Length', image.size);
    res.set('Cache-Control', 'public, max-age=31536000'); // Cache for 1 year
    
    // Send the image buffer
    res.send(image.data);
  } catch (error) {
    console.error('Error serving image:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving image'
    });
  }
});

module.exports = router;
