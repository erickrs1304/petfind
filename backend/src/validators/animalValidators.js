const { z } = require('zod');

// Campo opcional enviado vazio vira null: na edição, apagar a raça ou voltar o porte para
// "Não informado" limpa o valor salvo (antes o valor antigo continuava).
const vazioParaNull = (valor) => (valor === '' ? null : valor);

const createAnimalSchema = z.object({
  nome: z.string().min(1).max(50),
  especie: z.enum(['Cachorro', 'Gato', 'Outro']),
  raca: z.preprocess(vazioParaNull, z.string().max(50).nullable().optional()),
  porte: z.preprocess(vazioParaNull, z.enum(['Pequeno', 'Médio', 'Grande']).nullable().optional()),
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

const confirmSightingSchema = z.object({
  comentario: z.string().max(300).optional(),
});

module.exports = { createAnimalSchema, sightingSchema, confirmSightingSchema };
