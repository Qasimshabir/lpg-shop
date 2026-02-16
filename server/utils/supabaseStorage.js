const { supabase } = require('../config/supabase');
const logger = require('../config/logger');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

/**
 * Upload image to Supabase Storage
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} fileName - Original file name
 * @param {string} bucket - Storage bucket name (default: 'product-images')
 * @returns {Promise<{success: boolean, url?: string, error?: string}>}
 */
async function uploadImage(fileBuffer, fileName, bucket = 'product-images') {
  try {
    // Generate unique file name
    const fileExt = path.extname(fileName);
    const uniqueFileName = `${uuidv4()}${fileExt}`;
    const filePath = `products/${uniqueFileName}`;

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, fileBuffer, {
        contentType: getContentType(fileExt),
        cacheControl: '3600',
        upsert: false
      });

    if (error) {
      logger.error('Error uploading to Supabase Storage:', error);
      return { success: false, error: error.message };
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(bucket)
      .getPublicUrl(filePath);

    return {
      success: true,
      url: urlData.publicUrl,
      path: filePath
    };
  } catch (error) {
    logger.error('Error in uploadImage:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Delete image from Supabase Storage
 * @param {string} filePath - File path in storage
 * @param {string} bucket - Storage bucket name
 * @returns {Promise<{success: boolean, error?: string}>}
 */
async function deleteImage(filePath, bucket = 'product-images') {
  try {
    const { error } = await supabase.storage
      .from(bucket)
      .remove([filePath]);

    if (error) {
      logger.error('Error deleting from Supabase Storage:', error);
      return { success: false, error: error.message };
    }

    return { success: true };
  } catch (error) {
    logger.error('Error in deleteImage:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Update image (delete old and upload new)
 * @param {string} oldFilePath - Old file path to delete
 * @param {Buffer} newFileBuffer - New file buffer
 * @param {string} newFileName - New file name
 * @param {string} bucket - Storage bucket name
 * @returns {Promise<{success: boolean, url?: string, error?: string}>}
 */
async function updateImage(oldFilePath, newFileBuffer, newFileName, bucket = 'product-images') {
  try {
    // Delete old image if exists
    if (oldFilePath) {
      await deleteImage(oldFilePath, bucket);
    }

    // Upload new image
    return await uploadImage(newFileBuffer, newFileName, bucket);
  } catch (error) {
    logger.error('Error in updateImage:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Get content type based on file extension
 * @param {string} fileExt - File extension
 * @returns {string} Content type
 */
function getContentType(fileExt) {
  const contentTypes = {
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml'
  };

  return contentTypes[fileExt.toLowerCase()] || 'application/octet-stream';
}

/**
 * Extract file path from Supabase Storage URL
 * @param {string} url - Full Supabase Storage URL
 * @returns {string|null} File path or null
 */
function extractFilePathFromUrl(url) {
  try {
    if (!url) return null;
    
    // Extract path after /storage/v1/object/public/bucket-name/
    const match = url.match(/\/storage\/v1\/object\/public\/[^/]+\/(.+)$/);
    return match ? match[1] : null;
  } catch (error) {
    logger.error('Error extracting file path:', error);
    return null;
  }
}

/**
 * Validate image file
 * @param {Buffer} fileBuffer - File buffer
 * @param {string} fileName - File name
 * @param {number} maxSizeMB - Maximum file size in MB (default: 5)
 * @returns {{valid: boolean, error?: string}}
 */
function validateImage(fileBuffer, fileName, maxSizeMB = 5) {
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  const fileExt = path.extname(fileName).toLowerCase();

  // Check file extension
  if (!allowedExtensions.includes(fileExt)) {
    return {
      valid: false,
      error: `Invalid file type. Allowed types: ${allowedExtensions.join(', ')}`
    };
  }

  // Check file size
  const fileSizeMB = fileBuffer.length / (1024 * 1024);
  if (fileSizeMB > maxSizeMB) {
    return {
      valid: false,
      error: `File size exceeds ${maxSizeMB}MB limit`
    };
  }

  return { valid: true };
}

module.exports = {
  uploadImage,
  deleteImage,
  updateImage,
  extractFilePathFromUrl,
  validateImage,
  getContentType
};
