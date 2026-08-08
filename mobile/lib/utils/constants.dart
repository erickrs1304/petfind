import 'package:flutter/foundation.dart';

// Endereço da API, resolvido automaticamente conforme a plataforma:
// - Web/Windows desktop: localhost aponta diretamente para a máquina que roda o back-end.
// - Emulador Android: 10.0.2.2 é o endereço que o emulador usa para alcançar o localhost do host.
// Em um dispositivo físico, troque pelo IP da máquina na mesma rede Wi-Fi,
// ex.: 'http://192.168.0.10:3000'.
String get kApiBaseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

const double kDefaultNotificationRadiusKm = 5;
