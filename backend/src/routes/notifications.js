const express = require('express');
const { Notificacao } = require('../models');
const authMiddleware = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

// RF-008 - Listar notificações por proximidade do usuário logado
router.get('/', async (req, res) => {
  const notificacoes = await Notificacao.findAll({
    where: { usuarioId: req.userId },
    order: [['createdAt', 'DESC']],
  });
  return res.json(notificacoes);
});

router.post('/:id/read', async (req, res) => {
  const notificacao = await Notificacao.findByPk(req.params.id);
  if (!notificacao || notificacao.usuarioId !== req.userId) {
    return res.status(404).json({ error: 'Notificação não encontrada.' });
  }
  notificacao.lida = true;
  await notificacao.save();
  return res.json(notificacao);
});

module.exports = router;
