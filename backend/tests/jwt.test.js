const { signToken, verifyToken } = require('../src/utils/jwt');

// Teste unitário puro (sem app/banco) — cobre a emissão e verificação do token
// de sessão usado por authMiddleware em todas as rotas protegidas.
describe('jwt utils', () => {
  it('signToken gera um token que verifyToken consegue decodificar de volta ao mesmo payload', () => {
    const token = signToken({ userId: 42 });
    const payload = verifyToken(token);
    expect(payload.userId).toBe(42);
  });

  it('signToken gera tokens diferentes para payloads diferentes', () => {
    const tokenA = signToken({ userId: 1 });
    const tokenB = signToken({ userId: 2 });
    expect(tokenA).not.toBe(tokenB);
  });

  it('verifyToken lança erro para um token malformado', () => {
    expect(() => verifyToken('token-invalido')).toThrow();
  });

  it('verifyToken lança erro para um token assinado com outro segredo', () => {
    const jwt = require('jsonwebtoken');
    const tokenAlheio = jwt.sign({ userId: 1 }, 'outro-segredo');
    expect(() => verifyToken(tokenAlheio)).toThrow();
  });
});
