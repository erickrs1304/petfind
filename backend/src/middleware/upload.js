const path = require('path');
const crypto = require('crypto');
const multer = require('multer');

const MAX_SIZE_BYTES = 5 * 1024 * 1024; // 5MB (RF-004 / RF-006)
const BUCKET = process.env.SUPABASE_BUCKET || 'fotos';

// Com SUPABASE_URL + SUPABASE_SERVICE_KEY as fotos vão para o Supabase Storage
// (necessário em hospedagem serverless, que não tem disco gravável). Sem elas,
// continuam em backend/uploads, como em desenvolvimento local.
function usaStorage() {
  return Boolean(process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY);
}

function nomeDoArquivo(file) {
  const ext = path.extname(file.originalname) || '.jpg';
  return `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`;
}

const storage = usaStorage()
  ? multer.memoryStorage()
  : multer.diskStorage({
    destination: path.join(__dirname, '..', '..', 'uploads'),
    filename: (req, file, cb) => cb(null, nomeDoArquivo(file)),
  });

function fileFilter(req, file, cb) {
  const permitido = ['image/png', 'image/jpeg', 'image/jpg'];
  if (!permitido.includes(file.mimetype)) {
    return cb(new Error('A imagem deve ser PNG ou JPG.'));
  }
  cb(null, true);
}

const multerUpload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_BYTES },
});

async function enviarParaStorage(req, res, next) {
  if (!usaStorage() || !req.file) return next();

  const nome = nomeDoArquivo(req.file);
  const base = process.env.SUPABASE_URL.replace(/\/$/, '');
  try {
    const resposta = await fetch(`${base}/storage/v1/object/${BUCKET}/${nome}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_KEY}`,
        apikey: process.env.SUPABASE_SERVICE_KEY,
        'Content-Type': req.file.mimetype,
      },
      body: req.file.buffer,
    });
    if (!resposta.ok) throw new Error(`Storage respondeu ${resposta.status}`);
  } catch (err) {
    console.error('Falha ao enviar foto ao Supabase Storage:', err);
    return res.status(502).json({ error: 'Não foi possível salvar a foto. Tente novamente.' });
  }

  req.file.publicUrl = `${base}/storage/v1/object/public/${BUCKET}/${nome}`;
  return next();
}

// URL a gravar no banco: absoluta quando a foto está no Storage, relativa à API
// (/uploads/...) quando está em disco.
function urlDaFoto(file) {
  if (!file) return null;
  return file.publicUrl || `/uploads/${file.filename}`;
}

module.exports = {
  single: (campo) => [multerUpload.single(campo), enviarParaStorage],
  urlDaFoto,
};
