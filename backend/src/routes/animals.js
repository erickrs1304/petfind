const express = require('express');
const { Op } = require('sequelize');
const { Animal, Avistamento, Usuario } = require('../models');
const authMiddleware = require('../middleware/auth');
const upload = require('../middleware/upload');
const { urlDaFoto } = upload;
const { haversineDistanceKm } = require('../utils/geo');
const {
  notificarNovoCaso,
  notificarNovoAvistamento,
  notificarCasoEncerrado,
} = require('../services/notificationService');
const { createAnimalSchema, sightingSchema } = require('../validators/animalValidators');

const router = express.Router();
router.use(authMiddleware);

// RF-005 - Listar casos ativos, ordenados por proximidade, com filtro por espécie e busca por nome.
// `meus=true` restringe aos casos do tutor logado (tela "Meus Casos", RF-004 edição e RF-009 histórico).
// `raioKm` limita o resultado à vizinhança do usuário — o app amplia esse valor no fluxo "Ampliar busca" (RF-005 A1).
router.get('/', async (req, res) => {
  const { lat, lng, especie, nome, status, meus, raioKm } = req.query;

  const where = {};
  if (status !== 'TODOS') where.status = status || 'ATIVO';
  if (meus === 'true') where.usuarioId = req.userId;
  if (especie) where.especie = especie;
  if (nome) where.nome = { [Op.like]: `%${nome}%` };

  const animais = await Animal.findAll({ where, include: [{ model: Usuario, as: 'tutor', attributes: ['id', 'nome'] }] });

  const userLat = lat != null ? Number(lat) : null;
  const userLng = lng != null ? Number(lng) : null;
  const temLocalizacao = Number.isFinite(userLat) && Number.isFinite(userLng);

  let resultado = animais.map((animal) => {
    const distanciaKm = temLocalizacao ? haversineDistanceKm(userLat, userLng, animal.lat, animal.lng) : null;
    return { ...animal.toJSON(), distanciaKm };
  });

  const raio = Number(raioKm);
  if (temLocalizacao && Number.isFinite(raio) && raio > 0) {
    resultado = resultado.filter((animal) => animal.distanciaKm <= raio);
  }

  if (temLocalizacao) {
    resultado.sort((a, b) => a.distanciaKm - b.distanciaKm);
  }

  return res.json(resultado);
});

// RF-004 - Cadastrar caso de animal perdido
router.post('/', upload.single('foto'), async (req, res) => {
  const parsed = createAnimalSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Preencha todos os campos obrigatórios corretamente.', detalhes: parsed.error.flatten() });
  }
  const data = parsed.data;

  const dataDesaparecimento = new Date(data.dataDesaparecimento);
  if (dataDesaparecimento > new Date()) {
    return res.status(400).json({ error: 'A data não pode ser futura.' });
  }

  const animal = await Animal.create({
    ...data,
    usuarioId: req.userId,
    fotoUrl: urlDaFoto(req.file),
    status: 'ATIVO',
  });

  await notificarNovoCaso(animal);

  return res.status(201).json(animal);
});

// RF-004 - Consultar caso
router.get('/:id', async (req, res) => {
  const animal = await Animal.findByPk(req.params.id, {
    include: [{ model: Usuario, as: 'tutor', attributes: ['id', 'nome'] }],
  });
  if (!animal) return res.status(404).json({ error: 'Caso não encontrado.' });
  return res.json(animal);
});

// RF-004 - Editar caso (não altera status; apenas casos ativos são editáveis)
router.put('/:id', upload.single('foto'), async (req, res) => {
  const animal = await Animal.findByPk(req.params.id);
  if (!animal) return res.status(404).json({ error: 'Caso não encontrado.' });
  if (animal.usuarioId !== req.userId) return res.status(403).json({ error: 'Você não tem permissão para editar este caso.' });
  if (animal.status !== 'ATIVO') return res.status(400).json({ error: 'Este caso já foi encerrado e não pode mais ser editado.' });

  const parsed = createAnimalSchema.partial().safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Dados inválidos.', detalhes: parsed.error.flatten() });
  }

  if (parsed.data.dataDesaparecimento && new Date(parsed.data.dataDesaparecimento) > new Date()) {
    return res.status(400).json({ error: 'A data não pode ser futura.' });
  }

  Object.assign(animal, parsed.data);
  if (req.file) animal.fotoUrl = urlDaFoto(req.file);
  await animal.save();

  return res.json(animal);
});

// RF-009 - Encerrar caso (marcar como encontrado)
router.post('/:id/close', async (req, res) => {
  const animal = await Animal.findByPk(req.params.id);
  if (!animal) return res.status(404).json({ error: 'Caso não encontrado.' });
  if (animal.usuarioId !== req.userId) return res.status(403).json({ error: 'Você não tem permissão para encerrar este caso.' });
  if (animal.status !== 'ATIVO') return res.status(400).json({ error: 'Este caso já está encerrado.' });

  animal.status = 'ENCERRADO';
  animal.encerradoEm = new Date();
  await animal.save();

  await notificarCasoEncerrado(animal);

  return res.json(animal);
});

// RF-006 - Registrar avistamento com captura de GPS
router.post('/:id/sightings', upload.single('foto'), async (req, res) => {
  const animal = await Animal.findByPk(req.params.id);
  if (!animal) return res.status(404).json({ error: 'Caso não encontrado.' });
  if (animal.status !== 'ATIVO') {
    return res.status(400).json({ error: 'Este caso já foi encerrado. Não é possível registrar novos avistamentos.' });
  }
  if (animal.usuarioId === req.userId) {
    return res.status(403).json({
      error: 'Você é o tutor deste animal. Se encontrou o animal, encerre o caso em vez de registrar um avistamento.',
    });
  }

  const parsed = sightingSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Não foi possível obter sua localização. Ative o GPS e tente novamente.' });
  }

  const avistamento = await Avistamento.create({
    animalId: animal.id,
    usuarioId: req.userId,
    lat: parsed.data.lat,
    lng: parsed.data.lng,
    comentario: parsed.data.comentario,
    fotoUrl: urlDaFoto(req.file),
    dataHora: new Date(),
    status: 'PENDENTE',
  });

  await notificarNovoAvistamento(avistamento, animal);

  return res.status(201).json({ message: 'Avistamento registrado! O tutor será notificado.', avistamento });
});

// RF-007/RF-010 - Listar avistamentos de um caso (para mapa e para confirmação pelo tutor)
router.get('/:id/sightings', async (req, res) => {
  const { status } = req.query;
  const where = { animalId: req.params.id };
  if (status) where.status = status;

  const avistamentos = await Avistamento.findAll({
    where,
    include: [{ model: Usuario, as: 'colaborador', attributes: ['id', 'nome'] }],
    order: [['dataHora', 'ASC']],
  });

  return res.json(avistamentos);
});

module.exports = router;
