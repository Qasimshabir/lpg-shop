const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function ensureDirSync(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

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

// Save a data URI (e.g. data:image/jpeg;base64,...) to uploads/<subdir>/
// Returns the public URL path like /uploads/products/<filename>
function saveDataUriToFile(dataUri, subdir = 'products') {
  const match = /^data:([^;]+);base64,(.*)$/i.exec(dataUri);
  if (!match) {
    throw new Error('Invalid data URI');
  }
  const mime = match[1];
  const b64 = match[2];
  const ext = getExtFromMime(mime);
  const id = randomId();
  const fileName = `${id}.${ext}`;
  const uploadsRoot = path.join(__dirname, '..', 'uploads');
  const dir = path.join(uploadsRoot, subdir);
  ensureDirSync(dir);
  const absPath = path.join(dir, fileName);
  const buf = Buffer.from(b64, 'base64');
  fs.writeFileSync(absPath, buf);
  // Return public URL path that matches express.static mount
  const publicPath = `/uploads/${subdir}/${fileName}`;
  return { publicPath, absPath };
}

module.exports = {
  ensureDirSync,
  saveDataUriToFile,
};
