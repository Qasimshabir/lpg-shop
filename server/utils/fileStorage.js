const crypto = require('crypto');
const Image = require('../models/Image');

function getExtFromMime(mime) {
  switch (mime) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/gif':
      return 'gif';
    case 'image/webp':
      return 'webp';
    default:
      return 'bin';
  }
}

function randomId() {
  if (crypto.randomUUID) return crypto.randomUUID();
  return crypto.randomBytes(16).toString('hex');
}

// Save a data URI (e.g. data:image/jpeg;base64,...) to MongoDB
// Returns the public URL path like /api/images/<imageId>
async function saveDataUriToFile(dataUri, subdir = 'products', userId = null) {
  const match = /^data:([^;]+);base64,(.*)$/i.exec(dataUri);
  if (!match) {
    throw new Error('Invalid data URI');
  }
  const mime = match[1];
  const b64 = match[2];
  const ext = getExtFromMime(mime);
  const fileName = `${randomId()}.${ext}`;
  const buf = Buffer.from(b64, 'base64');
  
  try {
    // Save to MongoDB
    const image = new Image({
      filename: fileName,
      originalName: fileName,
      mimeType: mime,
      size: buf.length,
      data: buf,
      category: subdir,
      uploadedBy: userId
    });

    await image.save();
    
    // Return public URL path
    const publicPath = `/api/images/${image._id}`;
    return { publicPath, absPath: publicPath };
  } catch (error) {
    console.error('Error saving image to MongoDB:', error);
    throw error;
  }
}

// Get image from MongoDB by ID
async function getImageById(imageId) {
  try {
    const image = await Image.findById(imageId);
    return image;
  } catch (error) {
    console.error('Error retrieving image from MongoDB:', error);
    throw error;
  }
}

// Delete image from MongoDB
async function deleteImageById(imageId) {
  try {
    await Image.findByIdAndDelete(imageId);
    return true;
  } catch (error) {
    console.error('Error deleting image from MongoDB:', error);
    return false;
  }
}

module.exports = {
  saveDataUriToFile,
  getImageById,
  deleteImageById,
};
