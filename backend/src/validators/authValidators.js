const { z } = require('zod');
const { RAIO_MIN_KM, RAIO_MAX_KM } = require('../utils/geo');

const registerSchema = z.object({
  nome: z.string().min(1).max(100),
  email: z.string().email(),
  telefone: z.string().min(1).max(20),
  senha: z.string().min(6),
  confirmarSenha: z.string().min(6),
  regiao: z.string().min(1).max(150),
  lat: z.number().optional(),
  lng: z.number().optional(),
  notificacoesAtivas: z.boolean().optional(),
});

const loginSchema = z.object({
  email: z.string().email(),
  senha: z.string().min(1),
});

const forgotSchema = z.object({ email: z.string().email() });

const resetSchema = z.object({
  email: z.string().email(),
  codigo: z.string().length(6),
  novaSenha: z.string().min(6),
  confirmarNovaSenha: z.string().min(6),
});

const updateProfileSchema = z.object({
  nome: z.string().min(1).max(100).optional(),
  telefone: z.string().min(1).max(20).optional(),
  regiao: z.string().min(1).max(150).optional(),
  senha: z.string().min(6).optional(),
  lat: z.number().nullable().optional(),
  lng: z.number().nullable().optional(),
  raioNotificacaoKm: z.number().min(RAIO_MIN_KM).max(RAIO_MAX_KM).optional(),
  notificacoesAtivas: z.boolean().optional(),
});

const deleteAccountSchema = z.object({
  senha: z.string().min(1),
});

module.exports = { registerSchema, loginSchema, forgotSchema, resetSchema, updateProfileSchema, deleteAccountSchema };
