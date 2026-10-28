// RF-008: o raio de alcance das notificações é de 5 km por padrão e o usuário pode ajustá-lo de 1 a 20 km.
const RAIO_MIN_KM = 1;
const RAIO_MAX_KM = 20;

function toRad(value) {
  return (value * Math.PI) / 180;
}

// Distância em km entre dois pontos usando a fórmula de Haversine.
function haversineDistanceKm(lat1, lng1, lat2, lng2) {
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Raio considerado no envio dos alertas: um valor salvo antes da faixa existir conta como o limite mais próximo.
function raioNaFaixaKm(raioKm) {
  return Math.min(Math.max(raioKm, RAIO_MIN_KM), RAIO_MAX_KM);
}

module.exports = { haversineDistanceKm, raioNaFaixaKm, RAIO_MIN_KM, RAIO_MAX_KM };
