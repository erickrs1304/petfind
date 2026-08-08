import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/picked_photo.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dashed_photo_picker.dart';
import '../../widgets/location_capture_card.dart';
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
      final posicao = await obterLocalizacaoAtual();
      setState(() => _posicao = posicao);
    } on LocalizacaoException catch (e) {
      setState(() => _erro = e.message);
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
      showAppSnackBar(context, 'Avistamento registrado! O tutor será notificado.', type: AppSnackType.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível registrar o avistamento.'));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    backgroundColor: AppTheme.primaryStrong.withValues(alpha: 0.12),
                    backgroundImage: widget.animal.fotoUrlCompleta != null ? NetworkImage(widget.animal.fotoUrlCompleta!) : null,
                    child: widget.animal.fotoUrlCompleta == null ? const Icon(Icons.pets, color: AppTheme.primaryStrong) : null,
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
                          style: Theme.of(context).textTheme.bodySmall,
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
            LocationCaptureCard(
              obtendo: _obtendoLocalizacao,
              posicao: _posicao,
              erro: _erro,
              onRetry: _obterLocalizacao,
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
            Text(
              'O tutor será notificado imediatamente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
