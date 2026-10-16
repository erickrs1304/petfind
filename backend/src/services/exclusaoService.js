const { sequelize, Animal, Avistamento, Notificacao, Dispositivo } = require('../models');
const { removerFoto } = require('../middleware/upload');

// Remove do banco o caso, os avistamentos dele e as notificações que apontam para
// ele. Devolve as URLs das fotos para serem apagadas depois do commit.
async function apagarCaso(animal, transaction) {
  const avistamentos = await Avistamento.findAll({ where: { animalId: animal.id }, transaction });
  await Avistamento.destroy({ where: { animalId: animal.id }, transaction });
  await Notificacao.destroy({ where: { referenciaAnimalId: animal.id }, transaction });
  await animal.destroy({ transaction });
  return [animal.fotoUrl, ...avistamentos.map((avistamento) => avistamento.fotoUrl)];
}

// RF-004 - Excluir caso.
async function excluirCaso(animal) {
  const fotos = await sequelize.transaction((transaction) => apagarCaso(animal, transaction));
  await Promise.all(fotos.map(removerFoto));
}

// RF-001 - Excluir conta (LGPD, art. 18): apaga o usuário, os casos dele, os
// avistamentos que registrou, as notificações e os aparelhos cadastrados para push.
async function excluirConta(usuario) {
  const fotos = await sequelize.transaction(async (transaction) => {
    const casos = await Animal.findAll({ where: { usuarioId: usuario.id }, transaction });
    const fotosDosCasos = [];
    for (const caso of casos) {
      fotosDosCasos.push(...(await apagarCaso(caso, transaction)));
    }

    const avistamentos = await Avistamento.findAll({ where: { usuarioId: usuario.id }, transaction });
    await Avistamento.destroy({ where: { usuarioId: usuario.id }, transaction });
    await Notificacao.destroy({ where: { usuarioId: usuario.id }, transaction });
    await Dispositivo.destroy({ where: { usuarioId: usuario.id }, transaction });
    await usuario.destroy({ transaction });

    return [...fotosDosCasos, ...avistamentos.map((avistamento) => avistamento.fotoUrl)];
  });
  await Promise.all(fotos.map(removerFoto));
}

module.exports = { excluirCaso, excluirConta };
