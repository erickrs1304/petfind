const express = require('express');
const bcrypt = require('bcryptjs');
const { Usuario } = require('../models');
const { signToken } = require('../utils/jwt');
const authMiddleware = require('../middleware/auth');
const {
  registerSchema,
  loginSchema,
  forgotSchema,
  resetSchema,
  updateProfileSchema,
} = require('../validators/authValidators');

const router = express.Router();

const MAX_TENTATIVAS_LOGIN = 3;
const BLOQUEIO_LOGIN_MINUTOS = 5;

// RF-001 - Cadastro de usuário
router.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Preencha todos os campos obrigatórios corretamente.', detalhes: parsed.error.flatten() });
  }
  const { nome, email, telefone, senha, confirmarSenha, regiao, lat, lng } = parsed.data;

  if (senha !== confirmarSenha) {
    return res.status(400).json({ error: 'As senhas não coincidem.' });
  }

  const existente = await Usuario.findOne({ where: { email } });
  if (existente) {
    return res.status(409).json({ error: 'Este e-mail já está em uso.' });
  }

  const senhaHash = await bcrypt.hash(senha, 10);
  const usuario = await Usuario.create({ nome, email, telefone, senhaHash, regiao, lat, lng });

  return res.status(201).json({
    message: 'Cadastro realizado com sucesso!',
    usuario: { id: usuario.id, nome: usuario.nome, email: usuario.email },
  });
});

// RF-002 - Login
router.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'E-mail ou senha inválidos.' });
  }
  const { email, senha } = parsed.data;

  const usuario = await Usuario.findOne({ where: { email } });
  if (!usuario) {
    return res.status(401).json({ error: 'E-mail ou senha inválidos.' });
  }

  if (usuario.loginBloqueadoAte && new Date(usuario.loginBloqueadoAte) > new Date()) {
    return res.status(429).json({ error: 'Muitas tentativas. Recupere sua senha ou tente novamente em 5 minutos.' });
  }

  const senhaCorreta = await bcrypt.compare(senha, usuario.senhaHash);
  if (!senhaCorreta) {
    usuario.loginTentativasFalhas += 1;
    if (usuario.loginTentativasFalhas >= MAX_TENTATIVAS_LOGIN) {
      usuario.loginBloqueadoAte = new Date(Date.now() + BLOQUEIO_LOGIN_MINUTOS * 60 * 1000);
      usuario.loginTentativasFalhas = 0;
    }
    await usuario.save();
    return res.status(401).json({ error: 'E-mail ou senha inválidos.' });
  }

  usuario.loginTentativasFalhas = 0;
  usuario.loginBloqueadoAte = null;
  await usuario.save();

  const token = signToken({ userId: usuario.id });
  return res.json({
    token,
    usuario: {
      id: usuario.id,
      nome: usuario.nome,
      email: usuario.email,
      regiao: usuario.regiao,
      lat: usuario.lat,
      lng: usuario.lng,
      raioNotificacaoKm: usuario.raioNotificacaoKm,
    },
  });
});

// RF-003 - Solicitar código de recuperação de senha
// Ambiente de teste: sem serviço de e-mail configurado, o código é logado no console
// e devolvido em `devCode` para facilitar o teste manual do fluxo.
router.post('/forgot-password', async (req, res) => {
  const parsed = forgotSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Informe um e-mail válido.' });
  }
  const usuario = await Usuario.findOne({ where: { email: parsed.data.email } });
  if (!usuario) {
    return res.status(404).json({ error: 'E-mail não encontrado.' });
  }

  const codigo = String(Math.floor(100000 + Math.random() * 900000));
  usuario.resetCode = codigo;
  usuario.resetCodeExpiraEm = new Date(Date.now() + 15 * 60 * 1000);
  await usuario.save();

  // Mesmo motivo do handler de erro em app.js: em teste isso só some no ruído
  // (a suíte de RF-003 dispara este fluxo várias vezes de propósito).
  if (process.env.NODE_ENV !== 'test') {
    console.log(`[PetFind] Código de recuperação para ${usuario.email}: ${codigo}`);
  }

  return res.json({
    message: 'Código enviado. Verifique seu e-mail (modo teste: veja o console do servidor).',
    devCode: codigo,
  });
});

// RF-003 - Redefinir senha com código
router.post('/reset-password', async (req, res) => {
  const parsed = resetSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Dados inválidos.' });
  }
  const { email, codigo, novaSenha, confirmarNovaSenha } = parsed.data;

  if (novaSenha !== confirmarNovaSenha) {
    return res.status(400).json({ error: 'As senhas não coincidem.' });
  }

  const usuario = await Usuario.findOne({ where: { email } });
  if (!usuario || !usuario.resetCode) {
    return res.status(400).json({ error: 'Código inválido.' });
  }

  if (usuario.resetCodeExpiraEm && new Date(usuario.resetCodeExpiraEm) < new Date()) {
    return res.status(400).json({ error: 'Código expirado. Solicite um novo.' });
  }

  if (usuario.resetCode !== codigo) {
    return res.status(400).json({ error: 'Código inválido.' });
  }

  usuario.senhaHash = await bcrypt.hash(novaSenha, 10);
  usuario.resetCode = null;
  usuario.resetCodeExpiraEm = null;
  await usuario.save();

  return res.json({ message: 'Senha redefinida com sucesso.' });
});

// RF-001 - Consultar dados do próprio usuário
router.get('/me', authMiddleware, async (req, res) => {
  const usuario = await Usuario.findByPk(req.userId, {
    attributes: { exclude: ['senhaHash', 'resetCode', 'resetCodeExpiraEm'] },
  });
  if (!usuario) return res.status(404).json({ error: 'Usuário não encontrado.' });
  return res.json(usuario);
});

// RF-001 - Editar dados do próprio usuário
router.put('/me', authMiddleware, async (req, res) => {
  const parsed = updateProfileSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Dados inválidos.', detalhes: parsed.error.flatten() });
  }
  const usuario = await Usuario.findByPk(req.userId);
  if (!usuario) return res.status(404).json({ error: 'Usuário não encontrado.' });

  const { senha, ...resto } = parsed.data;
  Object.assign(usuario, resto);
  if (senha) usuario.senhaHash = await bcrypt.hash(senha, 10);
  await usuario.save();

  const { senhaHash, resetCode, resetCodeExpiraEm, ...usuarioSeguro } = usuario.toJSON();
  return res.json(usuarioSeguro);
});

module.exports = router;
