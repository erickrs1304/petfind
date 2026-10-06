jest.mock('../src/models', () => ({
  Usuario: { findAll: jest.fn() },
  Notificacao: { bulkCreate: jest.fn() },
  Avistamento: { findAll: jest.fn() },
}));

const { Usuario, Notificacao, Avistamento } = require('../src/models');
const {
  notificarNovoCaso,
  notificarNovoAvistamento,
  notificarCasoEncerrado,
} = require('../src/services/notificationService');

// Teste unitário puro (sem app/banco): os models Sequelize são substituídos por
// dublês, exercitando a lógica de elegibilidade/raio/duplicidade diretamente.
const TUTOR = { id: 1, lat: -17.79, lng: -50.91, raioNotificacaoKm: 5, notificacoesAtivas: true };
const VIZINHO_PERTO_ATIVO = { id: 2, lat: -17.7935, lng: -50.9188, raioNotificacaoKm: 5, notificacoesAtivas: true };
const VIZINHO_LONGE = { id: 3, lat: -16.6869, lng: -49.2648, raioNotificacaoKm: 5, notificacoesAtivas: true };
const VIZINHO_PERTO_INATIVO = { id: 4, lat: -17.7935, lng: -50.9188, raioNotificacaoKm: 5, notificacoesAtivas: false };
const ANIMAL = { id: 10, nome: 'Rex', usuarioId: TUTOR.id, lat: -17.7929, lng: -50.9188 };

beforeEach(() => {
  Usuario.findAll.mockReset();
  Notificacao.bulkCreate.mockReset();
  Avistamento.findAll.mockReset();
});

describe('notificarNovoCaso', () => {
  it('notifica o tutor mesmo com notificações desativadas ou fora de qualquer raio', async () => {
    Usuario.findAll.mockResolvedValue([{ ...TUTOR, notificacoesAtivas: false }]);

    await notificarNovoCaso(ANIMAL);

    expect(Notificacao.bulkCreate).toHaveBeenCalledWith([
      expect.objectContaining({ usuarioId: TUTOR.id, tipo: 'NOVO_CASO' }),
    ]);
  });

  it('notifica um vizinho dentro do raio com notificações ativas, mas não um vizinho longe nem um vizinho com notificações desativadas', async () => {
    Usuario.findAll.mockResolvedValue([TUTOR, VIZINHO_PERTO_ATIVO, VIZINHO_LONGE, VIZINHO_PERTO_INATIVO]);

    await notificarNovoCaso(ANIMAL);

    const idsNotificados = Notificacao.bulkCreate.mock.calls[0][0].map((n) => n.usuarioId);
    expect(idsNotificados).toEqual(expect.arrayContaining([TUTOR.id, VIZINHO_PERTO_ATIVO.id]));
    expect(idsNotificados).not.toContain(VIZINHO_LONGE.id);
    expect(idsNotificados).not.toContain(VIZINHO_PERTO_INATIVO.id);
  });

  it('não chama bulkCreate quando não há nenhum usuário elegível', async () => {
    Usuario.findAll.mockResolvedValue([]);

    await notificarNovoCaso(ANIMAL);

    expect(Notificacao.bulkCreate).not.toHaveBeenCalled();
  });
});

describe('notificarNovoAvistamento', () => {
  const AVISTAMENTO = { id: 20, usuarioId: VIZINHO_PERTO_ATIVO.id, lat: -17.7929, lng: -50.9188 };

  it('não notifica quem registrou o próprio avistamento, mesmo que seja o tutor', async () => {
    Usuario.findAll.mockResolvedValue([TUTOR, VIZINHO_PERTO_ATIVO]);
    const avistamentoDoTutor = { id: 21, usuarioId: TUTOR.id, lat: -17.7929, lng: -50.9188 };

    await notificarNovoAvistamento(avistamentoDoTutor, ANIMAL);

    const idsNotificados = Notificacao.bulkCreate.mock.calls[0][0].map((n) => n.usuarioId);
    expect(idsNotificados).not.toContain(TUTOR.id);
  });

  it('notifica o tutor e vizinhos próximos com notificações ativas, exceto o autor do avistamento', async () => {
    Usuario.findAll.mockResolvedValue([TUTOR, VIZINHO_PERTO_ATIVO, VIZINHO_LONGE]);

    await notificarNovoAvistamento(AVISTAMENTO, ANIMAL);

    const idsNotificados = Notificacao.bulkCreate.mock.calls[0][0].map((n) => n.usuarioId);
    expect(idsNotificados).toEqual(expect.arrayContaining([TUTOR.id]));
    expect(idsNotificados).not.toContain(VIZINHO_PERTO_ATIVO.id);
    expect(idsNotificados).not.toContain(VIZINHO_LONGE.id);
  });
});

describe('notificarCasoEncerrado', () => {
  it('notifica os colaboradores distintos que registraram avistamentos, excluindo o tutor', async () => {
    Avistamento.findAll.mockResolvedValue([
      { usuarioId: VIZINHO_PERTO_ATIVO.id },
      { usuarioId: VIZINHO_PERTO_ATIVO.id },
      { usuarioId: VIZINHO_LONGE.id },
      { usuarioId: TUTOR.id },
    ]);

    await notificarCasoEncerrado(ANIMAL);

    const chamada = Notificacao.bulkCreate.mock.calls[0][0];
    const idsNotificados = chamada.map((n) => n.usuarioId);
    expect(idsNotificados.sort()).toEqual([VIZINHO_LONGE.id, VIZINHO_PERTO_ATIVO.id].sort());
    expect(chamada).toHaveLength(2);
  });

  it('não chama bulkCreate quando não há colaboradores', async () => {
    Avistamento.findAll.mockResolvedValue([{ usuarioId: TUTOR.id }]);

    await notificarCasoEncerrado(ANIMAL);

    expect(Notificacao.bulkCreate).not.toHaveBeenCalled();
  });
});
