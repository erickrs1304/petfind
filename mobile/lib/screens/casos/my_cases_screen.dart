import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/case_card.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';
import 'case_detail_screen.dart';
import 'create_case_screen.dart';

// "Meus Casos" — ponto de partida do fluxo de edição do RF-004 (3.2) e da seção
// "Meus Casos Encerrados" exigida nas pós-condições do RF-009.
class MyCasesScreen extends StatefulWidget {
  const MyCasesScreen({super.key});

  @override
  State<MyCasesScreen> createState() => _MyCasesScreenState();
}

class _MyCasesScreenState extends State<MyCasesScreen> with SingleTickerProviderStateMixin {
  final _repository = AnimalRepository();
  late final TabController _tabController;

  List<Animal> _ativos = [];
  List<Animal> _encerrados = [];
  bool _carregando = true;
  String? _erro;

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
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final todos = await _repository.listarMeusCasos(status: 'TODOS');
      setState(() {
        _ativos = todos.where((a) => a.ativo).toList();
        _encerrados = todos.where((a) => !a.ativo).toList();
      });
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível carregar seus casos.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _editar(Animal animal) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateCaseScreen(animalParaEditar: animal)),
    );
    if (salvo == true) _carregar();
  }

  Future<void> _abrirDetalhes(Animal animal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CaseDetailScreen(animalId: animal.id)),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Meus Casos',
      subtitulo: 'Casos que você cadastrou',
      scrollable: false,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryStrong,
            indicatorColor: AppTheme.primaryStrong,
            unselectedLabelColor: AppTheme.textMuted,
            tabs: [
              Tab(text: 'Ativos (${_ativos.length})'),
              Tab(text: 'Encerrados (${_encerrados.length})'),
            ],
          ),
          Expanded(
            child: _carregando
                ? const LoadingView()
                : _erro != null
                    ? ErrorView(message: _erro!, onRetry: _carregar)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _lista(
                            casos: _ativos,
                            vazioTitulo: 'Você não tem casos ativos',
                            vazioSubtitulo: 'Os casos que você cadastrar aparecerão aqui para acompanhamento e edição.',
                          ),
                          _lista(
                            casos: _encerrados,
                            vazioTitulo: 'Nenhum caso encerrado',
                            vazioSubtitulo: 'Quando você marcar um animal como encontrado, o histórico ficará guardado aqui.',
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _lista({
    required List<Animal> casos,
    required String vazioTitulo,
    required String vazioSubtitulo,
  }) {
    if (casos.isEmpty) {
      return EmptyView(icon: Icons.folder_open_outlined, title: vazioTitulo, subtitle: vazioSubtitulo);
    }
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: casos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final animal = casos[index];
          return Column(
            children: [
              CaseCard(animal: animal, onTap: () => _abrirDetalhes(animal)),
              // Só casos ativos são editáveis — encerrados viram histórico (RF-009).
              if (animal.ativo)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _editar(animal),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: Text(
                      'Encerrado • desapareceu em ${formatarData(animal.dataDesaparecimento)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
