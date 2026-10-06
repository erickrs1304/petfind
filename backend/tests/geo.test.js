const { haversineDistanceKm } = require('../src/utils/geo');

// Teste unitário puro (sem app/banco) — cobre a fórmula que decide o raio das
// notificações por proximidade (RF-008) e da listagem por proximidade (RF-005).
describe('haversineDistanceKm', () => {
  it('retorna 0 para o mesmo ponto', () => {
    expect(haversineDistanceKm(-17.7929, -50.9188, -17.7929, -50.9188)).toBeCloseTo(0, 6);
  });

  it('calcula a distância entre dois pontos conhecidos (Rio Verde -> Goiânia, ~180km)', () => {
    // Rio Verde - GO (-17.7929, -50.9188) até Goiânia - GO (-16.6869, -49.2648)
    const distancia = haversineDistanceKm(-17.7929, -50.9188, -16.6869, -49.2648);
    expect(distancia).toBeGreaterThan(170);
    expect(distancia).toBeLessThan(220);
  });

  it('é simétrica: distância(A,B) === distância(B,A)', () => {
    const ab = haversineDistanceKm(-17.7929, -50.9188, -16.6869, -49.2648);
    const ba = haversineDistanceKm(-16.6869, -49.2648, -17.7929, -50.9188);
    expect(ab).toBeCloseTo(ba, 9);
  });

  it('distingue pontos próximos (~1km) de pontos distantes (~100km)', () => {
    const perto = haversineDistanceKm(-17.7929, -50.9188, -17.8019, -50.9188); // ~1km ao sul
    const longe = haversineDistanceKm(-17.7929, -50.9188, -16.7929, -50.9188); // ~111km ao norte

    expect(perto).toBeGreaterThan(0.5);
    expect(perto).toBeLessThan(1.5);
    expect(longe).toBeGreaterThan(100);
  });
});
