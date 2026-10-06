const express = require('express');
const { Avistamento, Animal, Notificacao } = require('../models');
const authMiddleware = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

// Carrega o avistamento garantindo que quem age é o tutor do caso e que o status
// atual permite a ação pedida (`statusPermitidos`).
async function carregarAvistamentoDoTutor(req, res, statusPermitidos) {
  const avistamento = await Avistamento.findByPk(req.params.id, { include: [{ model: Animal, as: 'animal' }] });
  if (!avistamento) {
    res.status(404).json({ error: 'Avistamento não encontrado.' });
    return null;
  }
  if (avistamento.animal.usuarioId !== req.userId) {
    res.status(403).json({ error: 'Apenas o tutor do animal pode confirmar ou excluir este avistamento.' });
    return null;
  }
  if (!statusPermitidos.includes(avistamento.status)) {
    res.status(400).json({ error: 'Este avistamento já foi analisado.' });
    return null;
  }
  return avistamento;
}

// RF-010 - Confirmar avistamento (passa a compor a trajetória no mapa)
router.post('/:id/confirm', async (req, res) => {
  const avistamento = await carregarAvistamentoDoTutor(req, res, ['PENDENTE']);
  if (!avistamento) return;

  avistamento.status = 'CONFIRMADO';
  if (req.body?.comentario) avistamento.comentario = req.body.comentario;
  await avistamento.save();

  await Notificacao.create({
    usuarioId: avistamento.usuarioId,
    tipo: 'AVISTAMENTO_CONFIRMADO',
    titulo: 'Avistamento confirmado',
    mensagem: 'O tutor confirmou seu avistamento. Obrigado por ajudar!',
    referenciaAnimalId: avistamento.animalId,
  });

  return res.json({ message: 'Avistamento confirmado e adicionado à trajetória!', avistamento });
});

// RF-010 - Excluir/rejeitar avistamento.
// Aceita também um avistamento já CONFIRMADO: o tutor pode ter confirmado por engano
// e precisa removê-lo da trajetória (RF-010, fluxo alternativo A2).
router.post('/:id/reject', async (req, res) => {
  const avistamento = await carregarAvistamentoDoTutor(req, res, ['PENDENTE', 'CONFIRMADO']);
  if (!avistamento) return;

  const estavaConfirmado = avistamento.status === 'CONFIRMADO';
  avistamento.status = 'REJEITADO';
  await avistamento.save();

  return res.json({
    message: estavaConfirmado
      ? 'Avistamento removido da trajetória.'
      : 'Avistamento excluído com sucesso.',
    avistamento,
  });
});

module.exports = router;
