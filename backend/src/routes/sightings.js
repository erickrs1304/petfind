const express = require('express');
const { Avistamento, Animal, Notificacao } = require('../models');
const authMiddleware = require('../middleware/auth');
const { enviarPush } = require('../services/pushService');
const { confirmSightingSchema } = require('../validators/animalValidators');

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
  const parsed = confirmSightingSchema.safeParse(req.body ?? {});
  if (!parsed.success) {
    return res.status(400).json({ error: 'O comentário deve ter no máximo 300 caracteres.' });
  }

  const avistamento = await carregarAvistamentoDoTutor(req, res, ['PENDENTE']);
  if (!avistamento) return;

  avistamento.status = 'CONFIRMADO';
  // O comentário de quem registrou o avistamento é mantido; o do tutor vai em campo próprio.
  if (parsed.data.comentario) avistamento.comentarioTutor = parsed.data.comentario;
  await avistamento.save();

  const notificacao = {
    usuarioId: avistamento.usuarioId,
    tipo: 'AVISTAMENTO_CONFIRMADO',
    titulo: 'Avistamento confirmado',
    mensagem: 'O tutor confirmou seu avistamento. Obrigado por ajudar!',
    referenciaAnimalId: avistamento.animalId,
  };
  await Notificacao.create(notificacao);
  await enviarPush([notificacao]);

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
