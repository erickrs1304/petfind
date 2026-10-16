import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/petfind_header.dart';

// RF-004 - O tutor marca no mapa o ponto do desaparecimento (Quadro 14: "campo texto + mapa").
// O ponto fica público no mapa do caso, por isso é escolhido pelo tutor em vez de ser
// capturado sozinho pelo GPS — quem publica de casa não expõe o próprio endereço.
class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key, required this.inicial});

  final LatLng inicial;

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  final _mapa = MapController();
  late LatLng _centro = widget.inicial;
  bool _obtendo = false;

  Future<void> _usarMinhaLocalizacao() async {
    setState(() => _obtendo = true);
    try {
      final posicao = await obterLocalizacaoAtual();
      final ponto = LatLng(posicao.latitude, posicao.longitude);
      _mapa.move(ponto, 17);
      setState(() => _centro = ponto);
    } on LocalizacaoException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _obtendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Ponto do desaparecimento',
      subtitulo: 'Arraste o mapa até o local',
      scrollable: false,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapa,
                  options: MapOptions(
                    initialCenter: widget.inicial,
                    initialZoom: 16,
                    onPositionChanged: (camera, _) => _centro = camera.center,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.petfind.app',
                    ),
                    // Crédito exigido pela licença do OpenStreetMap.
                    const SimpleAttributionWidget(source: Text('colaboradores do OpenStreetMap')),
                  ],
                ),
                // Alfinete fixo no centro: a ponta indica o ponto que será salvo.
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 44),
                      child: Icon(Icons.location_on, size: 48, color: AppTheme.dangerStrong),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Posicione o alfinete no lugar onde o animal foi visto pela última vez. Esse ponto aparece no mapa '
                  'do caso para todos os usuários.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _obtendo ? null : _usarMinhaLocalizacao,
                  icon: const Icon(Icons.my_location),
                  label: Text(_obtendo ? 'Obtendo localização...' : 'Usar minha localização atual'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(_centro),
                  icon: const Icon(Icons.check),
                  label: const Text('Usar este ponto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
