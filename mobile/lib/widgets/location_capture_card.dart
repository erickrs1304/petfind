import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Card que exibe o estado de captura de GPS (obtendo, erro com retry, ou
// posição confirmada). Usado em telas que precisam de localização exata
// (registrar avistamento, cadastrar/editar caso) para que o usuário sempre veja
// a coordenada que será enviada, nunca de forma silenciosa.
class LocationCaptureCard extends StatelessWidget {
  const LocationCaptureCard({
    super.key,
    required this.obtendo,
    required this.lat,
    required this.lng,
    required this.erro,
    required this.onRetry,
    this.tituloObtendo = 'Obtendo localização...',
    this.tituloOk = 'GPS capturado automaticamente',
    this.mostrarHorario = true,
    this.acaoExtra,
  });

  final bool obtendo;
  final double? lat;
  final double? lng;
  final String? erro;
  final VoidCallback onRetry;
  final String tituloObtendo;
  final String tituloOk;

  /// O horário só faz sentido quando a coordenada acabou de ser capturada.
  /// Na edição de um caso já existente ele é omitido.
  final bool mostrarHorario;

  /// Ação opcional abaixo da coordenada (ex.: "Atualizar com meu GPS atual").
  final Widget? acaoExtra;

  // O hemisfério já indica o sinal: -17.79 vira "17.7929° S" (antes saía "-17.7929° S").
  static String _coordenada(double lat, double lng) =>
      '${lat.abs().toStringAsFixed(4)}° ${lat < 0 ? 'S' : 'N'}, '
      '${lng.abs().toStringAsFixed(4)}° ${lng < 0 ? 'O' : 'L'}';

  @override
  Widget build(BuildContext context) {
    final agora = TimeOfDay.now();
    final temCoordenada = lat != null && lng != null;
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
            if (temCoordenada)
              Row(children: [
                const Icon(Icons.public, color: Colors.blueGrey, size: 18),
                const SizedBox(width: 8),
                Text(_coordenada(lat!, lng!), style: const TextStyle(fontSize: 13)),
              ]),
            if (mostrarHorario) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, color: Colors.blueGrey, size: 18),
                const SizedBox(width: 8),
                Text('Hoje, ${agora.format(context)}', style: const TextStyle(fontSize: 13)),
              ]),
            ],
            if (temCoordenada) ...[
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
            if (acaoExtra != null) ...[
              const SizedBox(height: 8),
              acaoExtra!,
            ],
          ],
          if (obtendo) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        ],
      ),
    );
  }
}
