jest.mock('../src/models', () => ({ Usuario: { findByPk: jest.fn() } }));

const { Usuario } = require('../src/models');
const { signToken } = require('../src/utils/jwt');
const authMiddleware = require('../src/middleware/auth');

// Teste unitário puro (sem app/banco/HTTP real): req/res/next e o model Usuario
// são substituídos por dublês, exercitando authMiddleware diretamente.
function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('authMiddleware', () => {
  beforeEach(() => {
    Usuario.findByPk.mockReset();
  });

  it('responde 401 quando o header Authorization não é enviado', async () => {
    const req = { headers: {} };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responde 401 quando o header não começa com "Bearer "', async () => {
    const req = { headers: { authorization: 'Token abc123' } };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responde 401 quando o token é inválido/expirado', async () => {
    const req = { headers: { authorization: 'Bearer token-invalido' } };
    const res = mockRes();
    const next = jest.fn();

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('responde 401 "Sessão expirada" quando o token é válido mas o usuário não existe mais (usuário órfão)', async () => {
    const token = signToken({ userId: 999 });
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();
    Usuario.findByPk.mockResolvedValue(null);

    await authMiddleware(req, res, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: expect.stringContaining('Sessão expirada') }));
    expect(next).not.toHaveBeenCalled();
  });

  it('chama next() e define req.userId quando o token é válido e o usuário existe', async () => {
    const token = signToken({ userId: 7 });
    const req = { headers: { authorization: `Bearer ${token}` } };
    const res = mockRes();
    const next = jest.fn();
    Usuario.findByPk.mockResolvedValue({ id: 7 });

    await authMiddleware(req, res, next);

    expect(req.userId).toBe(7);
    expect(next).toHaveBeenCalledTimes(1);
    expect(res.status).not.toHaveBeenCalled();
  });
});
