const express = require('express');
const bcrypt = require('bcryptjs');
const { Usuario } = require('../models');
const { signToken } = require('../utils/jwt');
const authMiddleware = require('../middleware/auth');
const { emailConfigurado, enviarCodigoRecuperacao } = require('../services/emailService');
const { excluirConta } = require('../services/exclusaoService');
const {
  registerSchema,
  loginSchema,
  forgotSchema,
  resetSchema,
  updateProfileSchema,
  deleteAccountSchema,
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
  const { nome, email, telefone, senha, confirmarSenha, regiao, notificacoesAtivas } = parsed.data;
  // A localização só é guardada com os alertas por proximidade ligados (escolha do usuário, LGPD).
  // Sem o campo (versões antigas do app), vale o padrão do modelo: alertas ligados.
  const usaLocalizacao = notificacoesAtivas !== false;
  const lat = usaLocalizacao ? parsed.data.lat : null;
  const lng = usaLocalizacao ? parsed.data.lng : null;

  if (senha !== confirmarSenha) {
    return res.status(400).json({ error: 'As senhas não coincidem.' });
  }

  const existente = await Usuario.findOne({ where: { email } });
  if (existente) {
    return res.status(409).json({ error: 'Este e-mail já está em uso.' });
  }

  const senhaHash = await bcrypt.hash(senha, 10);
  const usuario = await Usuario.create({
    nome, email, telefone, senhaHash, regiao, lat, lng, notificacoesAtivas: usaLocalizacao,
  });

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
    const bloqueou = usuario.loginTentativasFalhas >= MAX_TENTATIVAS_LOGIN;
    if (bloqueou) {
      usuario.loginBloqueadoAte = new Date(Date.now() + BLOQUEIO_LOGIN_MINUTOS * 60 * 1000);
      usuario.loginTentativasFalhas = 0;
    }
    await usuario.save();
    // RF-002 A2: a mensagem de bloqueio já aparece na 3ª tentativa errada.
    if (bloqueou) {
      return res.status(429).json({ error: 'Muitas tentativas. Recupere sua senha ou tente novamente em 5 minutos.' });
    }
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
      telefone: usuario.telefone,
      regiao: usuario.regiao,
      lat: usuario.lat,
      lng: usuario.lng,
      raioNotificacaoKm: usuario.raioNotificacaoKm,
      notificacoesAtivas: usuario.notificacoesAtivas,
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

  // Com SMTP configurado o código só vai por e-mail; devolvê-lo na resposta
  // permitiria a qualquer um redefinir a senha de outra pessoa. Sem SMTP, segue o
  // modo teste (código no console e em devCode).
  if (emailConfigurado()) {
    try {
      await enviarCodigoRecuperacao(usuario.email, usuario.nome, codigo);
    } catch (err) {
      console.error('Falha ao enviar e-mail de recuperação:', err);
      return res.status(502).json({ error: 'Não foi possível enviar o e-mail agora. Tente novamente em instantes.' });
    }
    return res.json({ message: 'Código enviado. Verifique seu e-mail (veja também a caixa de spam).' });
  }

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
  // Com os alertas por proximidade desligados, a localização não é guardada (e a salva é apagada),
  // mesmo que um aparelho com versão antiga do app continue enviando a posição.
  if (!usuario.notificacoesAtivas) {
    usuario.lat = null;
    usuario.lng = null;
  }
  if (senha) usuario.senhaHash = await bcrypt.hash(senha, 10);
  await usuario.save();

  const { senhaHash, resetCode, resetCodeExpiraEm, ...usuarioSeguro } = usuario.toJSON();
  return res.json(usuarioSeguro);
});

// RF-001 - Excluir a própria conta. Pede a senha para confirmar, porque não tem volta.
// Senha errada responde 400, não 401: o app trata 401 como sessão expirada e deslogaria.
router.delete('/me', authMiddleware, async (req, res) => {
  const parsed = deleteAccountSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Informe sua senha para excluir a conta.' });
  }
  const usuario = await Usuario.findByPk(req.userId);
  if (!usuario) return res.status(404).json({ error: 'Usuário não encontrado.' });

  const senhaCorreta = await bcrypt.compare(parsed.data.senha, usuario.senhaHash);
  if (!senhaCorreta) {
    return res.status(400).json({ error: 'Senha incorreta.' });
  }

  await excluirConta(usuario);

  return res.json({ message: 'Conta excluída.' });
});

module.exports = router;
