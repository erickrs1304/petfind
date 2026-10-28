import 'package:flutter/foundation.dart';

// Endereço da API. Prioridade:
// 1. --dart-define=API_BASE_URL=http://<ip-da-máquina>:3000 — obrigatório para
//    testar em um dispositivo físico (ex.: iPhone) via rede local, já que
//    "localhost" no dispositivo aponta para o próprio dispositivo, não para a
//    máquina que roda o back-end.
// 2. Sem a flag, cai no fallback automático por plataforma (comportamento
//    anterior, preservado): Web/desktop usa localhost; emulador Android usa
//    10.0.2.2 (endereço que o emulador usa para alcançar o host).
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL', defaultValue: '');

String get kApiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

const double kDefaultNotificationRadiusKm = 5;

// RF-008: o usuário pode ajustar o raio de alcance dos alertas de 1 a 20 km (o servidor valida a mesma faixa).
const double kMinNotificationRadiusKm = 1;
const double kMaxNotificationRadiusKm = 20;

// Política de privacidade publicada pela API (exigência da Google Play e da LGPD).
const String kPoliticaPrivacidadeUrl = 'https://petfind-beryl.vercel.app/privacidade';

// Centro do mapa de marcação do ponto do desaparecimento quando não há ponto marcado nem
// localização no perfil (Rio Verde - GO).
const double kCentroPadraoLat = -17.7929;
const double kCentroPadraoLng = -50.9188;
