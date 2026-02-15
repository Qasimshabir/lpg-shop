const crypto = require('crypto');
const { getSupabaseClient } = require('../config/supabase');

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

// Save a data URI (e.g. data:image/jpeg;base64,...) to Supabase
// Returns the public URL path
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
    const supabase = getSupabaseClient();
    
    // Save to Supabase images table
    const { data: image, error } = await supabase
      .from('images')
      .insert([{
        filename: fileName,
        original_name: fileName,
        mime_type: mime,
        size: buf.length,
        path: `/${subdir}/${fileName}`,
        url: `/api/images/${fileName}`,
        uploaded_by: userId
      }])
      .select()
      .single();

    if (error) throw error;
    
    // Return public URL path
    const publicPath = `/api/images/${image.id}`;
    return publicPath;
  } catch (error) {
    console.error('Error saving image to Supabase:', error);
    throw error;
  }
}

// Get image from Supabase by ID
async function getImageById(imageId) {
  try {
    const supabase = getSupabaseClient();
    
    const { data: image, error } = await supabase
      .from('images')
      .select('*')
      .eq('id', imageId)
      .single();

    if (error) throw error;
    return image;
  } catch (error) {
    console.error('Error retrieving image from Supabase:', error);
    throw error;
  }
}

// Delete image from Supabase
async function deleteImageById(imageId) {
  try {
    const supabase = getSupabaseClient();
    
    const { error } = await supabase
      .from('images')
      .delete()
      .eq('id', imageId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error deleting image from Supabase:', error);
    return false;
  }
}

module.exports = {
  saveDataUriToFile,
  getImageById,
  deleteImageById,
};
