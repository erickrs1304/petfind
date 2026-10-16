jest.mock('../src/models', () => ({
  sequelize: { transaction: jest.fn() },
  Animal: { findAll: jest.fn() },
  Avistamento: { findAll: jest.fn(), destroy: jest.fn() },
  Notificacao: { destroy: jest.fn() },
  Dispositivo: { destroy: jest.fn() },
}));
jest.mock('../src/middleware/upload', () => ({ removerFoto: jest.fn() }));

const { sequelize, Animal, Avistamento, Notificacao, Dispositivo } = require('../src/models');
const { removerFoto } = require('../src/middleware/upload');
const { excluirCaso, excluirConta } = require('../src/services/exclusaoService');

// Teste unitário puro (sem app/banco): models, transação e remoção de fotos são
// dublês, exercitando o que cada exclusão apaga e em que ordem.
const T = 'transacao';

function caso(id, fotoUrl) {
  return { id, fotoUrl, destroy: jest.fn() };
}

beforeEach(() => {
  jest.clearAllMocks();
  sequelize.transaction.mockImplementation((fn) => fn(T));
});

describe('excluirCaso', () => {
  it('apaga avistamentos, notificações e o caso na transação e depois as fotos', async () => {
    const animal = caso(10, 'foto-caso.jpg');
    Avistamento.findAll.mockResolvedValue([{ fotoUrl: 'foto-avist.jpg' }, { fotoUrl: null }]);

    await excluirCaso(animal);

    expect(Avistamento.destroy).toHaveBeenCalledWith({ where: { animalId: 10 }, transaction: T });
    expect(Notificacao.destroy).toHaveBeenCalledWith({ where: { referenciaAnimalId: 10 }, transaction: T });
    expect(animal.destroy).toHaveBeenCalledWith({ transaction: T });
    expect(removerFoto.mock.calls.map((c) => c[0])).toEqual(['foto-caso.jpg', 'foto-avist.jpg', null]);
  });

  it('não apaga nenhuma foto se a transação falhar', async () => {
    sequelize.transaction.mockRejectedValue(new Error('falha no banco'));

    await expect(excluirCaso(caso(10, 'foto-caso.jpg'))).rejects.toThrow('falha no banco');
    expect(removerFoto).not.toHaveBeenCalled();
  });
});

describe('excluirConta', () => {
  it('apaga os casos do usuário, os avistamentos que ele registrou, notificações, aparelhos e o próprio usuário', async () => {
    const usuario = { id: 1, destroy: jest.fn() };
    const casoDoUsuario = caso(10, 'foto-caso.jpg');
    Animal.findAll.mockResolvedValue([casoDoUsuario]);
    Avistamento.findAll
      .mockResolvedValueOnce([{ fotoUrl: 'avist-no-caso.jpg' }]) // avistamentos do caso 10
      .mockResolvedValueOnce([{ fotoUrl: 'avist-do-usuario.jpg' }]); // avistamentos feitos pelo usuário

    await excluirConta(usuario);

    expect(casoDoUsuario.destroy).toHaveBeenCalledWith({ transaction: T });
    expect(Avistamento.destroy).toHaveBeenCalledWith({ where: { usuarioId: 1 }, transaction: T });
    expect(Notificacao.destroy).toHaveBeenCalledWith({ where: { usuarioId: 1 }, transaction: T });
    expect(Dispositivo.destroy).toHaveBeenCalledWith({ where: { usuarioId: 1 }, transaction: T });
    expect(usuario.destroy).toHaveBeenCalledWith({ transaction: T });
    expect(removerFoto.mock.calls.map((c) => c[0])).toEqual(['foto-caso.jpg', 'avist-no-caso.jpg', 'avist-do-usuario.jpg']);
  });
});
