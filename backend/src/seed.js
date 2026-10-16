require('dotenv').config();
const bcrypt = require('bcryptjs');
const { sequelize, Usuario, Animal, Avistamento, Notificacao } = require('./models');

// Coordenadas de referência: Rio Verde - GO
const BASE_LAT = -17.7929;
const BASE_LNG = -50.9188;

async function seed() {
  await sequelize.sync({ force: true });

  const senhaHash = await bcrypt.hash('123456', 10);

  // O quarto usuário (Diego) só existe para testar o raio de notificação; não é referenciado depois.
  const [ana, bruno, carla] = await Usuario.bulkCreate([
    { nome: 'Ana Souza', email: 'ana@petfind.com', telefone: '(64) 99999-0001', senhaHash, regiao: 'Setor Central, Rio Verde', lat: BASE_LAT, lng: BASE_LNG, raioNotificacaoKm: 5 },
    { nome: 'Bruno Lima', email: 'bruno@petfind.com', telefone: '(64) 99999-0002', senhaHash, regiao: 'Vila Borges, Rio Verde', lat: BASE_LAT + 0.01, lng: BASE_LNG + 0.008, raioNotificacaoKm: 5 },
    { nome: 'Carla Nunes', email: 'carla@petfind.com', telefone: '(64) 99999-0003', senhaHash, regiao: 'Jardim Goiás, Rio Verde', lat: BASE_LAT - 0.015, lng: BASE_LNG + 0.012, raioNotificacaoKm: 5 },
    { nome: 'Diego Alves', email: 'diego@petfind.com', telefone: '(64) 99999-0004', senhaHash, regiao: 'Centro, Rio Verde', lat: BASE_LAT + 0.3, lng: BASE_LNG + 0.3, raioNotificacaoKm: 5 },
  ]);

  const thor = await Animal.create({
    usuarioId: ana.id,
    nome: 'Thor',
    especie: 'Cachorro',
    raca: 'Vira-lata',
    porte: 'Médio',
    caracteristicas: 'Pelagem caramelo, coleira azul, uma orelha caída.',
    dataDesaparecimento: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
    ultimaLocalizacaoTexto: 'Praça do Setor Central, Rio Verde',
    lat: BASE_LAT,
    lng: BASE_LNG,
    status: 'ATIVO',
  });

  const mimi = await Animal.create({
    usuarioId: bruno.id,
    nome: 'Mimi',
    especie: 'Gato',
    raca: 'Siamês',
    porte: 'Pequeno',
    caracteristicas: 'Pelo curto claro, olhos azuis, muito arisca.',
    dataDesaparecimento: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10),
    ultimaLocalizacaoTexto: 'Rua das Flores, Vila Borges, Rio Verde',
    lat: BASE_LAT + 0.01,
    lng: BASE_LNG + 0.008,
    status: 'ATIVO',
  });

  await Avistamento.create({
    animalId: thor.id,
    usuarioId: carla.id,
    lat: BASE_LAT + 0.004,
    lng: BASE_LNG + 0.003,
    comentario: 'Vi um cachorro parecido correndo perto do mercado.',
    status: 'CONFIRMADO',
    dataHora: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
  });

  await Avistamento.create({
    animalId: thor.id,
    usuarioId: carla.id,
    lat: BASE_LAT + 0.007,
    lng: BASE_LNG + 0.006,
    comentario: 'Mesmo cachorro, agora perto da praça.',
    status: 'PENDENTE',
    dataHora: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
  });

  await Notificacao.create({
    usuarioId: ana.id,
    tipo: 'NOVO_AVISTAMENTO',
    titulo: 'Novo avistamento!',
    mensagem: `NOVO AVISTAMENTO! Alguém viu ${thor.nome} próximo a você.`,
    referenciaAnimalId: thor.id,
  });

  await Notificacao.create({
    usuarioId: bruno.id,
    tipo: 'NOVO_CASO',
    titulo: 'Caso registrado',
    mensagem: `Seu caso de ${mimi.nome} foi registrado e está ativo.`,
    referenciaAnimalId: mimi.id,
  });

  console.log('Seed concluído. Usuários de teste (senha: 123456):');
  console.log('  ana@petfind.com (tutora do Thor)');
  console.log('  bruno@petfind.com (tutor da Mimi)');
  console.log('  carla@petfind.com (colaboradora, já registrou avistamentos)');
  console.log('  diego@petfind.com (usuário distante, fora do raio de notificação)');
  await sequelize.close();
}

seed().catch((err) => {
  console.error('Falha ao popular banco de dados:', err);
  process.exit(1);
});
