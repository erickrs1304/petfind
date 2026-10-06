import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/avistamento.dart';
import '../../data/repositories/animal_repository.dart';
import '../../data/repositories/sighting_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';

// RF-010 - Confirmar/Excluir Avistamento (Figura 13).
// A aba "Confirmados" cobre o fluxo alternativo A2: o tutor que confirmou por
// engano pode remover o avistamento da trajetória.
class ConfirmSightingsScreen extends StatefulWidget {
  const ConfirmSightingsScreen({super.key, required this.animal});

  final Animal animal;

  @override
  State<ConfirmSightingsScreen> createState() => _ConfirmSightingsScreenState();
}

class _ConfirmSightingsScreenState extends State<ConfirmSightingsScreen> with SingleTickerProviderStateMixin {
  final _animalRepository = AnimalRepository();
  final _sightingRepository = SightingRepository();
  late final TabController _tabController;

  List<Avistamento> _pendentes = [];
  List<Avistamento> _confirmados = [];
  bool _carregando = true;
  bool _houveAlteracao = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final pendentes = await _animalRepository.listarAvistamentos(widget.animal.id, status: 'PENDENTE');
      final confirmados = await _animalRepository.listarAvistamentos(widget.animal.id, status: 'CONFIRMADO');
      if (!mounted) return;
      setState(() {
        _pendentes = pendentes;
        _confirmados = confirmados;
      });
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, extractErrorMessage(e), type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _confirmar(Avistamento avistamento) async {
    final controller = TextEditingController();
    final comentario = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar avistamento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Deseja adicionar algum comentário sobre este avistamento?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Confirmar')),
        ],
      ),
    );
    controller.dispose();
    if (comentario == null) return;

    await _executar(
      () => _sightingRepository.confirmar(avistamento.id, comentario: comentario),
      sucesso: 'Avistamento confirmado e adicionado à trajetória!',
    );
  }

  Future<void> _excluir(Avistamento avistamento) async {
    final jaConfirmado = avistamento.status == 'CONFIRMADO';
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jaConfirmado ? 'Remover da trajetória' : 'Excluir avistamento'),
        content: Text(
          jaConfirmado
              ? 'Este avistamento já foi confirmado e está na trajetória. Deseja removê-lo?'
              : 'Tem certeza que deseja excluir este avistamento? Esta ação é irreversível.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerStrong),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(jaConfirmado ? 'Sim, remover' : 'Sim, excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    await _executar(
      () => _sightingRepository.excluir(avistamento.id),
      sucesso: jaConfirmado ? 'Avistamento removido da trajetória.' : 'Avistamento excluído com sucesso.',
    );
  }

  Future<void> _executar(Future<void> Function() acao, {required String sucesso}) async {
    try {
      await acao();
      _houveAlteracao = true;
      if (!mounted) return;
      showAppSnackBar(context, sucesso, type: AppSnackType.success);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, extractErrorMessage(e), type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_houveAlteracao);
      },
      child: PetFindScaffold(
        titulo: 'Avistamentos',
        subtitulo: 'Confirme, exclua ou revise os registros',
        scrollable: false,
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryStrong,
              indicatorColor: AppTheme.primaryStrong,
              unselectedLabelColor: AppTheme.textMuted,
              tabs: [
                Tab(text: 'Pendentes (${_pendentes.length})'),
                Tab(text: 'Confirmados (${_confirmados.length})'),
              ],
            ),
            Expanded(
              child: _carregando
                  ? const LoadingView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _lista(
                          avistamentos: _pendentes,
                          vazioTitulo: 'Nenhum avistamento pendente de análise.',
                          vazioSubtitulo: 'Avistamentos registrados por outras pessoas aparecerão aqui para você confirmar.',
                        ),
                        _lista(
                          avistamentos: _confirmados,
                          vazioTitulo: 'Nenhum avistamento confirmado ainda.',
                          vazioSubtitulo: 'Os avistamentos que você confirmar compõem a trajetória no mapa.',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista({
    required List<Avistamento> avistamentos,
    required String vazioTitulo,
    required String vazioSubtitulo,
  }) {
    if (avistamentos.isEmpty) {
      return EmptyView(
        icon: Icons.playlist_add_check_outlined,
        title: vazioTitulo,
        subtitle: vazioSubtitulo,
      );
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: avistamentos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _card(avistamentos[index], index),
      ),
    );
  }

  Widget _card(Avistamento avistamento, int index) {
    final confirmado = avistamento.status == 'CONFIRMADO';
    final cor = confirmado ? AppTheme.successStrong : AppTheme.primaryStrong;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cor, width: 4)),
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
                    Text(avistamento.colaboradorNome ?? 'Colaborador', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      formatarDataHoraRelativa(avistamento.dataHora),
                      style: Theme.of(context).textTheme.bodySmall,
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
              if (confirmado)
                // A2 - desfazer uma confirmação feita por engano.
                TextButton.icon(
                  onPressed: () => _excluir(avistamento),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.dangerStrong),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Remover da trajetória'),
                )
              else ...[
                IconButton.filled(
                  onPressed: () => _excluir(avistamento),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.dangerStrong),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _confirmar(avistamento),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.successStrong),
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
