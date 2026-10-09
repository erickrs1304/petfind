import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/avistamento.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/share_helper.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';

// RF-007 - Visualizar Mapa (Figura 10): última localização, avistamentos
// confirmados numerados e conectados cronologicamente por uma trajetória pontilhada.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// Avistamentos que caem praticamente no mesmo ponto viram um marcador só,
/// com contador (RF-007, fluxo alternativo A2).
class _GrupoAvistamentos {
  _GrupoAvistamentos(this.avistamentos);

  final List<Avistamento> avistamentos;

  LatLng get ponto => LatLng(avistamentos.first.lat, avistamentos.first.lng);
  int get quantidade => avistamentos.length;
}

class _MapScreenState extends State<MapScreen> {
  // ~4 casas decimais equivalem a cerca de 11 metros: perto o bastante para que
  // dois registros representem "o mesmo local" aos olhos do usuário.
  static const _precisaoAgrupamento = 4;

  final _repository = AnimalRepository();
  List<Avistamento> _confirmados = [];
  List<_GrupoAvistamentos> _grupos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final confirmados = await _repository.listarAvistamentos(widget.animal.id, status: 'CONFIRMADO');
      if (!mounted) return;
      setState(() {
        _confirmados = confirmados;
        _grupos = _agrupar(confirmados);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<_GrupoAvistamentos> _agrupar(List<Avistamento> avistamentos) {
    final porLocal = <String, List<Avistamento>>{};
    // A lista vem ordenada por data/hora, então a ordem dos grupos preserva a cronologia.
    for (final avistamento in avistamentos) {
      final chave = '${avistamento.lat.toStringAsFixed(_precisaoAgrupamento)},'
          '${avistamento.lng.toStringAsFixed(_precisaoAgrupamento)}';
      porLocal.putIfAbsent(chave, () => []).add(avistamento);
    }
    return porLocal.values.map(_GrupoAvistamentos.new).toList();
  }

  Widget _pinNumerado(int numero, Color cor, String rotulo, {int quantidade = 1}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              alignment: Alignment.center,
              child: Text('$numero', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            // Contador do agrupamento (A2).
            if (quantidade > 1)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBadge,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text('$quantidade', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)]),
          child: Text(rotulo, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final centro = LatLng(widget.animal.lat, widget.animal.lng);
    final pontosTrajetoria = [centro, ..._confirmados.map((a) => LatLng(a.lat, a.lng))];
    // Quadro 17 do DERS: o raio de busca acompanha o avistamento mais recente;
    // sem avistamentos, fica no ponto do desaparecimento.
    final centroRaio = _confirmados.isEmpty ? centro : LatLng(_confirmados.last.lat, _confirmados.last.lng);

    return PetFindScaffold(
      titulo: 'Mapa do Caso',
      subtitulo: '${widget.animal.nome} • ${_confirmados.length} avistamentos',
      scrollable: false,
      body: _carregando
          ? const LoadingView()
          : _erro != null
              ? ErrorView(message: _erro!, onRetry: _carregar)
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(initialCenter: centro, initialZoom: 14),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.petfind.app',
                        ),
                        CircleLayer(circles: [
                          CircleMarker(
                            point: centroRaio,
                            radius: kDefaultNotificationRadiusKm * 1000,
                            useRadiusInMeter: true,
                            color: AppTheme.primaryStrong.withValues(alpha: 0.08),
                            borderColor: AppTheme.primaryStrong.withValues(alpha: 0.4),
                            borderStrokeWidth: 1,
                          ),
                        ]),
                        if (pontosTrajetoria.length > 1)
                          PolylineLayer(polylines: [
                            Polyline(points: pontosTrajetoria, color: AppTheme.primaryStrong, strokeWidth: 3, pattern: const StrokePattern.dotted()),
                          ]),
                        MarkerLayer(markers: [
                          Marker(
                            point: centro,
                            width: 70,
                            height: 56,
                            alignment: Alignment.topCenter,
                            child: _pinNumerado(1, AppTheme.dangerStrong, 'Última loc.'),
                          ),
                          for (var i = 0; i < _grupos.length; i++)
                            Marker(
                              point: _grupos[i].ponto,
                              width: 70,
                              height: 56,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _mostrarGrupo(_grupos[i]),
                                child: _pinNumerado(
                                  i + 2,
                                  AppTheme.primaryStrong,
                                  _grupos[i].quantidade > 1 ? '${_grupos[i].quantidade} avist.' : 'Avist. ${i + 1}',
                                  quantidade: _grupos[i].quantidade,
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 14,
                            runSpacing: 6,
                            children: [
                              _legenda(AppTheme.dangerStrong, 'Última loc.'),
                              _legenda(AppTheme.primaryStrong, 'Avistamentos'),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(width: 16, height: 2, color: AppTheme.primaryStrong),
                                const SizedBox(width: 4),
                                const Text('Trajetória', style: TextStyle(fontSize: 11)),
                              ]),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primaryStrong.withValues(alpha: 0.15),
                                    border: Border.all(color: AppTheme.primaryStrong.withValues(alpha: 0.5)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('Raio de 5 km', style: TextStyle(fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // RF-007 A1 - sem avistamentos confirmados, orienta a divulgar o caso.
                    if (_confirmados.isEmpty)
                      Positioned(
                        left: 24,
                        right: 24,
                        top: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Nenhum avistamento confirmado ainda. Compartilhe para ajudar!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => compartilharCaso(widget.animal),
                                  icon: const Icon(Icons.share_outlined, size: 18),
                                  label: const Text('Compartilhar caso'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _legenda(Color cor, String texto) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, color: cor, size: 10),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ]);

  void _mostrarGrupo(_GrupoAvistamentos grupo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: grupo.quantidade > 1 ? 0.5 : 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            if (grupo.quantidade > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${grupo.quantidade} avistamentos neste local',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            for (final avistamento in grupo.avistamentos) _detalhesAvistamento(avistamento, grupo.quantidade > 1),
          ],
        ),
      ),
    );
  }

  Widget _detalhesAvistamento(Avistamento avistamento, bool emGrupo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emGrupo) const Divider(),
          Text(formatarDataHora(avistamento.dataHora), style: Theme.of(context).textTheme.titleMedium),
          if (avistamento.colaboradorNome != null) Text('Registrado por ${avistamento.colaboradorNome}'),
          if (avistamento.comentario != null && avistamento.comentario!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(avistamento.comentario!),
          ],
          if (avistamento.fotoUrlCompleta != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(avistamento.fotoUrlCompleta!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
        ],
      ),
    );
  }
}
