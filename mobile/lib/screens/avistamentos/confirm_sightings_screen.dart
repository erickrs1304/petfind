import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/avistamento.dart';
import '../../data/repositories/animal_repository.dart';
import '../../data/repositories/sighting_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/petfind_header.dart';

// RF-010 - Confirmar/Excluir Avistamento (Figura 13)
class ConfirmSightingsScreen extends StatefulWidget {
  const ConfirmSightingsScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<ConfirmSightingsScreen> createState() => _ConfirmSightingsScreenState();
}

class _ConfirmSightingsScreenState extends State<ConfirmSightingsScreen> {
  final _animalRepository = AnimalRepository();
  final _sightingRepository = SightingRepository();

  List<Avistamento> _pendentes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _pendentes = await _animalRepository.listarAvistamentos(widget.animal.id, status: 'PENDENTE');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmar(Avistamento avistamento) async {
    final comentario = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Confirmar avistamento'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Deseja adicionar algum comentário sobre este avistamento?'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Confirmar')),
          ],
        );
      },
    );
    if (comentario == null) return;

    try {
      await _sightingRepository.confirmar(avistamento.id, comentario: comentario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avistamento confirmado e adicionado à trajetória!')),
      );
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    }
  }

  Future<void> _excluir(Avistamento avistamento) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir avistamento'),
        content: const Text('Tem certeza que deseja excluir este avistamento? Esta ação é irreversível.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _sightingRepository.excluir(avistamento.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avistamento excluído com sucesso.')));
      _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Avistamentos',
      subtitulo: 'Confirme ou exclua os registros pendentes',
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _pendentes.isEmpty
              ? const Center(child: Text('Nenhum avistamento pendente.'))
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendentes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final avistamento = _pendentes[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.secondaryBadge,
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        avistamento.colaboradorNome ?? 'Colaborador',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Hoje ${avistamento.dataHora.hour.toString().padLeft(2, '0')}:${avistamento.dataHora.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (avistamento.comentario != null && avistamento.comentario!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(avistamento.comentario!),
                            ],
                            if (avistamento.fotoUrlCompleta != null) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(avistamento.fotoUrlCompleta!, height: 140, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton.filled(
                                  onPressed: () => _excluir(avistamento),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.danger),
                                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  onPressed: () => _confirmar(avistamento),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.success),
                                  icon: const Icon(Icons.check, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
