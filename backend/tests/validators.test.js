const {
  registerSchema, loginSchema, resetSchema, updateProfileSchema, deleteAccountSchema,
} = require('../src/validators/authValidators');
const { createAnimalSchema, sightingSchema } = require('../src/validators/animalValidators');

// Teste unitário puro (sem app/banco/HTTP): valida os schemas Zod diretamente,
// os mesmos usados pelas rotas via safeParse.
describe('authValidators', () => {
  const cadastroValido = {
    nome: 'Erick',
    email: 'erick@example.com',
    telefone: '64999990000',
    senha: 'senha123',
    confirmarSenha: 'senha123',
    regiao: 'Rio Verde - GO',
  };

  it('registerSchema aceita um cadastro válido', () => {
    expect(registerSchema.safeParse(cadastroValido).success).toBe(true);
  });

  it('registerSchema rejeita e-mail inválido', () => {
    const resultado = registerSchema.safeParse({ ...cadastroValido, email: 'nao-e-email' });
    expect(resultado.success).toBe(false);
  });

  it('registerSchema rejeita senha com menos de 6 caracteres', () => {
    const resultado = registerSchema.safeParse({ ...cadastroValido, senha: '123', confirmarSenha: '123' });
    expect(resultado.success).toBe(false);
  });

  it('loginSchema rejeita senha vazia', () => {
    expect(loginSchema.safeParse({ email: 'erick@example.com', senha: '' }).success).toBe(false);
  });

  it('resetSchema exige código com exatamente 6 caracteres', () => {
    const base = { email: 'erick@example.com', novaSenha: 'novasenha', confirmarNovaSenha: 'novasenha' };
    expect(resetSchema.safeParse({ ...base, codigo: '12345' }).success).toBe(false);
    expect(resetSchema.safeParse({ ...base, codigo: '123456' }).success).toBe(true);
  });

  it('updateProfileSchema aceita objeto vazio (todos os campos são opcionais)', () => {
    expect(updateProfileSchema.safeParse({}).success).toBe(true);
  });

  it('updateProfileSchema rejeita raioNotificacaoKm negativo', () => {
    expect(updateProfileSchema.safeParse({ raioNotificacaoKm: -5 }).success).toBe(false);
  });

  it('aceita a escolha de não usar a localização: alertas desligados no cadastro e lat/lng nulos no perfil', () => {
    expect(registerSchema.safeParse({ ...cadastroValido, notificacoesAtivas: false }).success).toBe(true);
    expect(updateProfileSchema.safeParse({ notificacoesAtivas: false, lat: null, lng: null }).success).toBe(true);
  });

  it('deleteAccountSchema exige a senha para confirmar a exclusão da conta', () => {
    expect(deleteAccountSchema.safeParse({}).success).toBe(false);
    expect(deleteAccountSchema.safeParse({ senha: '' }).success).toBe(false);
    expect(deleteAccountSchema.safeParse({ senha: 'senha123' }).success).toBe(true);
  });
});

describe('animalValidators', () => {
  const casoValido = {
    nome: 'Rex',
    especie: 'Cachorro',
    caracteristicas: 'Coleira azul, porte médio',
    dataDesaparecimento: '2026-01-10',
    ultimaLocalizacaoTexto: 'Praça Central',
    lat: -17.7929,
    lng: -50.9188,
  };

  it('createAnimalSchema aceita um caso válido', () => {
    expect(createAnimalSchema.safeParse(casoValido).success).toBe(true);
  });

  it('createAnimalSchema rejeita espécie fora do conjunto fechado', () => {
    expect(createAnimalSchema.safeParse({ ...casoValido, especie: 'Passarinho' }).success).toBe(false);
  });

  it('createAnimalSchema rejeita porte fora do conjunto fechado (regressão do bug de texto livre)', () => {
    expect(createAnimalSchema.safeParse({ ...casoValido, porte: 'médio' }).success).toBe(false);
    expect(createAnimalSchema.safeParse({ ...casoValido, porte: 'Médio' }).success).toBe(true);
  });

  it('createAnimalSchema converte lat/lng em string para number (coerce)', () => {
    const resultado = createAnimalSchema.safeParse({ ...casoValido, lat: '-17.79', lng: '-50.91' });
    expect(resultado.success).toBe(true);
    expect(resultado.data.lat).toBe(-17.79);
  });

  it('sightingSchema rejeita lat/lng ausentes', () => {
    expect(sightingSchema.safeParse({ comentario: 'vi o cachorro' }).success).toBe(false);
  });

  it('sightingSchema aceita comentário opcional ausente', () => {
    expect(sightingSchema.safeParse({ lat: -17.79, lng: -50.91 }).success).toBe(true);
  });
});
