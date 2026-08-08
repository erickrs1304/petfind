import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/avistamento.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/petfind_header.dart';

// RF-007 - Visualizar Mapa (Figura 10): última localização, avistamentos
// confirmados numerados e conectados cronologicamente por uma trajetória pontilhada.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repository = AnimalRepository();
  List<Avistamento> _confirmados = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _confirmados = await _repository.listarAvistamentos(widget.animal.id, status: 'CONFIRMADO');
    } catch (e) {
      _erro = extractErrorMessage(e);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _pinNumerado(int numero, Color cor, String rotulo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          alignment: Alignment.center,
          child: Text('$numero', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

    return PetFindScaffold(
      titulo: 'Mapa do Caso',
      subtitulo: '${widget.animal.nome} • ${_confirmados.length} avistamentos',
      scrollable: false,
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
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
                            point: centro,
                            radius: 5000,
                            useRadiusInMeter: true,
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderColor: AppTheme.primary.withValues(alpha: 0.4),
                            borderStrokeWidth: 1,
                          ),
                        ]),
                        if (pontosTrajetoria.length > 1)
                          PolylineLayer(polylines: [
                            Polyline(points: pontosTrajetoria, color: AppTheme.primary, strokeWidth: 3, pattern: const StrokePattern.dotted()),
                          ]),
                        MarkerLayer(markers: [
                          Marker(
                            point: centro,
                            width: 70,
                            height: 56,
                            alignment: Alignment.topCenter,
                            child: _pinNumerado(1, AppTheme.danger, 'Última loc.'),
                          ),
                          for (var i = 0; i < _confirmados.length; i++)
                            Marker(
                              point: LatLng(_confirmados[i].lat, _confirmados[i].lng),
                              width: 70,
                              height: 56,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _mostrarDetalhesAvistamento(_confirmados[i]),
                                child: _pinNumerado(i + 2, AppTheme.primary, 'Avist. ${i + 1}'),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _legenda(AppTheme.danger, 'Última loc.'),
                              _legenda(AppTheme.primary, 'Avistamentos'),
                              Row(children: [
                                Container(width: 16, height: 2, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                const Text('Trajetória', style: TextStyle(fontSize: 11)),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_confirmados.isEmpty)
                      Positioned(
                        left: 24,
                        right: 24,
                        top: 16,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Nenhum avistamento confirmado ainda. Compartilhe para ajudar!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
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

  void _mostrarDetalhesAvistamento(Avistamento avistamento) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${avistamento.dataHora.day}/${avistamento.dataHora.month} às ${avistamento.dataHora.hour}:${avistamento.dataHora.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium),
            if (avistamento.colaboradorNome != null) Text('Registrado por ${avistamento.colaboradorNome}'),
            if (avistamento.comentario != null && avistamento.comentario!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(avistamento.comentario!),
            ],
            if (avistamento.fotoUrlCompleta != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(avistamento.fotoUrlCompleta!, height: 160, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
