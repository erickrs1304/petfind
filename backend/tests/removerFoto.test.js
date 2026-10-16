jest.mock('fs/promises', () => ({ unlink: jest.fn() }));

const fs = require('fs/promises');
const { removerFoto } = require('../src/middleware/upload');

// Teste unitário puro (sem Storage real): fetch e fs são dublês.
const BASE = 'https://projeto.supabase.co';

beforeEach(() => {
  jest.clearAllMocks();
  global.fetch = jest.fn().mockResolvedValue({ ok: true });
  process.env.SUPABASE_URL = BASE;
  process.env.SUPABASE_SERVICE_KEY = 'chave-de-teste';
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  delete process.env.SUPABASE_URL;
  delete process.env.SUPABASE_SERVICE_KEY;
  console.error.mockRestore();
});

describe('removerFoto', () => {
  it('não faz nada quando o registro não tem foto', async () => {
    await removerFoto(null);

    expect(global.fetch).not.toHaveBeenCalled();
    expect(fs.unlink).not.toHaveBeenCalled();
  });

  it('pede ao Supabase Storage a exclusão do objeto da foto', async () => {
    await removerFoto(`${BASE}/storage/v1/object/public/fotos/123-abc.jpg`);

    expect(global.fetch).toHaveBeenCalledWith(
      `${BASE}/storage/v1/object/fotos/123-abc.jpg`,
      expect.objectContaining({ method: 'DELETE' }),
    );
  });

  it('apaga do disco a foto salva localmente em /uploads', async () => {
    await removerFoto('/uploads/123-abc.jpg');

    expect(fs.unlink).toHaveBeenCalledWith(expect.stringMatching(/uploads[\\/]123-abc\.jpg$/));
    expect(global.fetch).not.toHaveBeenCalled();
  });

  it('registra a falha do Storage sem lançar erro', async () => {
    global.fetch.mockResolvedValue({ ok: false, status: 500 });

    await expect(removerFoto(`${BASE}/storage/v1/object/public/fotos/x.jpg`)).resolves.toBeUndefined();
    expect(console.error).toHaveBeenCalled();
  });
});
