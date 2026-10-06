const { z } = require('zod');

const createAnimalSchema = z.object({
  nome: z.string().min(1).max(50),
  especie: z.enum(['Cachorro', 'Gato', 'Outro']),
  raca: z.string().max(50).optional(),
  porte: z.enum(['Pequeno', 'Médio', 'Grande']).optional(),
  caracteristicas: z.string().min(1).max(200),
  dataDesaparecimento: z.string(), // YYYY-MM-DD
  ultimaLocalizacaoTexto: z.string().min(1).max(200),
  lat: z.coerce.number(),
  lng: z.coerce.number(),
});

const sightingSchema = z.object({
  lat: z.coerce.number(),
  lng: z.coerce.number(),
  comentario: z.string().max(300).optional(),
});

module.exports = { createAnimalSchema, sightingSchema };
