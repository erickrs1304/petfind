import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/picked_photo.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dashed_photo_picker.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/status_chip.dart';

// RF-006 - Registrar Avistamento (Figura 9)
class RegisterSightingScreen extends StatefulWidget {
  const RegisterSightingScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<RegisterSightingScreen> createState() => _RegisterSightingScreenState();
}

class _RegisterSightingScreenState extends State<RegisterSightingScreen> {
  final _repository = AnimalRepository();
  final _comentarioController = TextEditingController();

  Position? _posicao;
  PickedPhoto? _foto;
  bool _obtendoLocalizacao = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _obterLocalizacao();
  }

  Future<void> _obterLocalizacao() async {
    setState(() {
      _obtendoLocalizacao = true;
      _erro = null;
    });
    try {
      final habilitado = await Geolocator.isLocationServiceEnabled();
      if (!habilitado) throw Exception('gps-desativado');

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
        throw Exception('permissao-negada');
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _posicao = posicao);
    } catch (_) {
      setState(() => _erro = 'Não foi possível obter sua localização. Ative o GPS e tente novamente.');
    } finally {
      if (mounted) setState(() => _obtendoLocalizacao = false);
    }
  }

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (imagem == null) return;
    final bytes = await imagem.readAsBytes();
    setState(() => _foto = PickedPhoto(bytes: bytes, filename: imagem.name));
  }

  Future<void> _registrar() async {
    if (_posicao == null) {
      setState(() => _erro = 'Não foi possível obter sua localização. Ative o GPS e tente novamente.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await _repository.registrarAvistamento(
        animalId: widget.animal.id,
        lat: _posicao!.latitude,
        lng: _posicao!.longitude,
        comentario: _comentarioController.text.trim(),
        foto: _foto,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avistamento registrado! O tutor será notificado.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível registrar o avistamento.'));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agora = TimeOfDay.now();
    return PetFindScaffold(
      titulo: 'Vi Este Animal',
      subtitulo: 'Registrar avistamento',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                    backgroundImage: widget.animal.fotoUrlCompleta != null ? NetworkImage(widget.animal.fotoUrlCompleta!) : null,
                    child: widget.animal.fotoUrlCompleta == null ? const Icon(Icons.pets, color: AppTheme.primaryDark) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.animal.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          [widget.animal.especie, if (widget.animal.porte != null) 'Porte ${widget.animal.porte}', if (widget.animal.raca != null) widget.animal.raca!]
                              .join(' • '),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        StatusChip(status: widget.animal.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Localização capturada'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_erro != null) ...[
                    Text(_erro!, style: const TextStyle(color: AppTheme.danger)),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _obterLocalizacao, child: const Text('Tentar novamente')),
                    const SizedBox(height: 8),
                  ] else ...[
                    Row(children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryDark, size: 18),
                      const SizedBox(width: 8),
                      Text(_obtendoLocalizacao ? 'Obtendo localização...' : 'GPS capturado automaticamente', style: const TextStyle(fontSize: 13)),
                    ]),
                    const SizedBox(height: 6),
                    if (_posicao != null)
                      Row(children: [
                        const Icon(Icons.public, color: Colors.blueGrey, size: 18),
                        const SizedBox(width: 8),
                        Text('${_posicao!.latitude.toStringAsFixed(4)}° S, ${_posicao!.longitude.toStringAsFixed(4)}° O', style: const TextStyle(fontSize: 13)),
                      ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time, color: Colors.blueGrey, size: 18),
                      const SizedBox(width: 8),
                      Text('Hoje, ${agora.format(context)}', style: const TextStyle(fontSize: 13)),
                    ]),
                    if (_posicao != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.success, borderRadius: BorderRadius.circular(24)),
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
                  if (_obtendoLocalizacao) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Foto do avistamento (opcional)'),
            DashedPhotoPicker(onTap: _selecionarFoto, fotoBytes: _foto?.bytes, texto: 'Adicionar foto do avistamento'),
            const SizedBox(height: 20),
            const SectionLabel('Comentário (opcional)'),
            AppTextField(
              label: '',
              hintText: 'Ex: Vi o animal próximo ao mercado, estava sozinho...',
              controller: _comentarioController,
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (_enviando || _posicao == null) ? null : _registrar,
              icon: _enviando ? null : const Icon(Icons.send_outlined),
              label: _enviando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar Avistamento'),
            ),
            const SizedBox(height: 6),
            const Text('O tutor será notificado imediatamente', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
