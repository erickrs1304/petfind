import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/status_chip.dart';

// RF-009 - Encerrar Caso (Figura 12)
class CloseCaseScreen extends StatefulWidget {
  const CloseCaseScreen({super.key, required this.animal, required this.totalAvistamentos});

  final Animal animal;
  final int totalAvistamentos;

  @override
  State<CloseCaseScreen> createState() => _CloseCaseScreenState();
}

class _CloseCaseScreenState extends State<CloseCaseScreen> {
  final _repository = AnimalRepository();
  bool _carregando = false;

  Future<void> _confirmarEncerramento() async {
    setState(() => _carregando = true);
    try {
      await _repository.encerrarCaso(widget.animal.id);
      if (!mounted) return;
      showAppSnackBar(context, 'Que ótimo! Seu amigo está de volta!', type: AppSnackType.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, extractErrorMessage(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final dias = DateTime.now().difference(animal.dataDesaparecimento).inDays;

    return PetFindScaffold(
      titulo: 'Encerrar Caso',
      subtitulo: '${animal.nome} foi encontrado?',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppTheme.successGradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.celebration_outlined, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Que notícia incrível! Marque o caso como encontrado para encerrar os alertas e notificar a comunidade.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text('O histórico do caso será mantido no sistema', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryStrong.withValues(alpha: 0.12),
                    backgroundImage: animal.fotoUrlCompleta != null ? NetworkImage(animal.fotoUrlCompleta!) : null,
                    child: animal.fotoUrlCompleta == null ? const Icon(Icons.pets, color: AppTheme.primaryStrong) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(animal.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Desaparecido há $dias dias • ${widget.totalAvistamentos} avistamentos', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        StatusChip(status: animal.status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionLabel('Resumo do caso'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _linhaResumo(Icons.calendar_today_outlined,
                      'Desapareceu em: ${animal.dataDesaparecimento.day.toString().padLeft(2, '0')}/${animal.dataDesaparecimento.month.toString().padLeft(2, '0')}/${animal.dataDesaparecimento.year}'),
                  _linhaResumo(Icons.location_on_outlined, 'Última localização: ${animal.ultimaLocalizacaoTexto}'),
                  _linhaResumo(Icons.groups_outlined, 'Colaboradores: ${widget.totalAvistamentos} avistamentos registrados'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregando ? null : _confirmarEncerramento,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successStrong),
              icon: _carregando ? null : const Icon(Icons.check_circle_outline),
              label: _carregando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Encontrei meu animal!'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Manter caso ativo'),
            ),
            const SizedBox(height: 6),
            Text('Esta ação encerrará os alertas e notificará a comunidade', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _linhaResumo(IconData icone, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppTheme.primaryStrong),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
