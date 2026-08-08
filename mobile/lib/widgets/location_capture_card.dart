import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';

// Card que exibe o estado de captura de GPS (obtendo, erro com retry, ou
// posição confirmada). Usado em telas que precisam de localização exata
// (registrar avistamento, cadastrar caso) para que o usuário sempre veja a
// coordenada que será enviada, nunca de forma silenciosa.
class LocationCaptureCard extends StatelessWidget {
  const LocationCaptureCard({
    super.key,
    required this.obtendo,
    required this.posicao,
    required this.erro,
    required this.onRetry,
    this.tituloObtendo = 'Obtendo localização...',
    this.tituloOk = 'GPS capturado automaticamente',
  });

  final bool obtendo;
  final Position? posicao;
  final String? erro;
  final VoidCallback onRetry;
  final String tituloObtendo;
  final String tituloOk;

  @override
  Widget build(BuildContext context) {
    final agora = TimeOfDay.now();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (erro != null) ...[
            Text(erro!, style: const TextStyle(color: AppTheme.dangerStrong)),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            const SizedBox(height: 8),
          ] else ...[
            Row(children: [
              const Icon(Icons.location_on, color: AppTheme.primaryStrong, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(obtendo ? tituloObtendo : tituloOk, style: const TextStyle(fontSize: 13))),
            ]),
            const SizedBox(height: 6),
            if (posicao != null)
              Row(children: [
                const Icon(Icons.public, color: Colors.blueGrey, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${posicao!.latitude.toStringAsFixed(4)}° S, ${posicao!.longitude.toStringAsFixed(4)}° O',
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.access_time, color: Colors.blueGrey, size: 18),
              const SizedBox(width: 8),
              Text('Hoje, ${agora.format(context)}', style: const TextStyle(fontSize: 13)),
            ]),
            if (posicao != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: AppTheme.successStrong, borderRadius: BorderRadius.circular(24)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Localização confirmada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
          if (obtendo) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
