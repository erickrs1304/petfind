const { verifyToken } = require('../utils/jwt');
const { Usuario } = require('../models');

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de autenticação não informado.' });
  }
  const token = header.slice('Bearer '.length);

  let payload;
  try {
    payload = verifyToken(token);
  } catch (err) {
    return res.status(401).json({ error: 'Token inválido ou expirado.' });
  }

  // A assinatura do token continua válida mesmo depois que o usuário deixa de
  // existir (ex.: banco recriado pelo seed). Sem esta checagem, o pedido seguia
  // com um usuarioId órfão e quebrava mais adiante na chave estrangeira.
  const usuario = await Usuario.findByPk(payload.userId, { attributes: ['id'] });
  if (!usuario) {
    return res.status(401).json({ error: 'Sessão expirada. Entre novamente.' });
  }

  req.userId = usuario.id;
  next();
}

module.exports = authMiddleware;
