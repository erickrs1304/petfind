const path = require('path');
const crypto = require('crypto');
const multer = require('multer');

const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5MB (RF-004 / RF-006)

const storage = multer.diskStorage({
  destination: path.join(__dirname, '..', '..', 'uploads'),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
  },
});

function fileFilter(req, file, cb) {
  const permitido = ['image/png', 'image/jpeg', 'image/jpg'];
  if (!permitido.includes(file.mimetype)) {
    return cb(new Error('A imagem deve ser PNG ou JPG.'));
  }
  cb(null, true);
}

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_BYTES },
});

module.exports = upload;
