const { Usuario, Notificacao, Avistamento } = require('../models');
const { haversineDistanceKm } = require('../utils/geo');

// Dispara notificações de proximidade para um novo caso (RF-004 + RF-008).
// O tutor é sempre notificado; demais usuários dentro do raio configurado por cada um recebem alerta.
async function notificarNovoCaso(animal) {
  const usuarios = await Usuario.findAll();
  const notificacoes = [];

  for (const usuario of usuarios) {
    const ehTutor = usuario.id === animal.usuarioId;
    const dentroDoRaio =
      usuario.lat != null &&
      usuario.lng != null &&
      haversineDistanceKm(usuario.lat, usuario.lng, animal.lat, animal.lng) <= usuario.raioNotificacaoKm;

    if (!ehTutor && (!usuario.notificacoesAtivas || !dentroDoRaio)) continue;

    notificacoes.push({
      usuarioId: usuario.id,
      tipo: 'NOVO_CASO',
      titulo: ehTutor ? 'Caso registrado' : 'Novo caso próximo a você',
      mensagem: ehTutor
        ? `Seu caso de ${animal.nome} foi registrado e está ativo.`
        : `NOVO CASO: ${animal.nome} desapareceu próximo a você!`,
      referenciaAnimalId: animal.id,
    });
  }

  if (notificacoes.length) await Notificacao.bulkCreate(notificacoes);
}

// Dispara notificação do novo avistamento para o tutor (sempre) e demais usuários próximos (RF-006 + RF-008).
async function notificarNovoAvistamento(avistamento, animal) {
  const usuarios = await Usuario.findAll();
  const notificacoes = [];

  for (const usuario of usuarios) {
    const ehAutorDoAvistamento = usuario.id === avistamento.usuarioId;
    if (ehAutorDoAvistamento) continue;

    const ehTutor = usuario.id === animal.usuarioId;
    const dentroDoRaio =
      usuario.lat != null &&
      usuario.lng != null &&
      haversineDistanceKm(usuario.lat, usuario.lng, avistamento.lat, avistamento.lng) <= usuario.raioNotificacaoKm;

    if (!ehTutor && (!usuario.notificacoesAtivas || !dentroDoRaio)) continue;

    notificacoes.push({
      usuarioId: usuario.id,
      tipo: 'NOVO_AVISTAMENTO',
      titulo: ehTutor ? 'Novo avistamento!' : 'Avistamento próximo a você',
      mensagem: ehTutor
        ? `NOVO AVISTAMENTO! Alguém viu ${animal.nome} próximo a você.`
        : `Um avistamento de ${animal.nome} foi registrado próximo a você.`,
      referenciaAnimalId: animal.id,
    });
  }

  if (notificacoes.length) await Notificacao.bulkCreate(notificacoes);
}

// Avisa quem colaborou com o caso que a busca terminou (RF-009).
// Só os colaboradores são notificados: o tutor é quem executa o encerramento e já vê o resultado na tela.
async function notificarCasoEncerrado(animal) {
  const avistamentos = await Avistamento.findAll({
    where: { animalId: animal.id },
    attributes: ['usuarioId'],
  });

  const colaboradores = [...new Set(avistamentos.map((a) => a.usuarioId))].filter((id) => id !== animal.usuarioId);
  if (!colaboradores.length) return;

  await Notificacao.bulkCreate(
    colaboradores.map((usuarioId) => ({
      usuarioId,
      tipo: 'CASO_ENCERRADO',
      titulo: 'Caso encerrado',
      mensagem: `Boa notícia! ${animal.nome} foi encontrado. Obrigado por ajudar na busca!`,
      referenciaAnimalId: animal.id,
    })),
  );
}

module.exports = { notificarNovoCaso, notificarNovoAvistamento, notificarCasoEncerrado };
