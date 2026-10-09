const express = require('express');
const { Dispositivo } = require('../models');
const authMiddleware = require('../middleware/auth');
const { deviceTokenSchema } = require('../validators/deviceValidators');

const router = express.Router();
router.use(authMiddleware);

// RF-008 - O app registra o token FCM do celular após o login. O mesmo token passa
// a pertencer a quem logou por último (troca de conta no mesmo aparelho).
router.post('/', async (req, res) => {
  const parsed = deviceTokenSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Token do dispositivo inválido.' });
  }
  const { token } = parsed.data;
  const existente = await Dispositivo.findOne({ where: { token } });
  if (existente) {
    if (existente.usuarioId !== req.userId) {
      existente.usuarioId = req.userId;
      await existente.save();
    }
  } else {
    await Dispositivo.create({ usuarioId: req.userId, token });
  }
  return res.status(204).end();
});

// Ao sair da conta, o app remove o token para não receber push de quem saiu.
router.delete('/', async (req, res) => {
  const parsed = deviceTokenSchema.safeParse({ token: req.query.token });
  if (!parsed.success) {
    return res.status(400).json({ error: 'Token do dispositivo inválido.' });
  }
  await Dispositivo.destroy({ where: { token: parsed.data.token, usuarioId: req.userId } });
  return res.status(204).end();
});

module.exports = router;
