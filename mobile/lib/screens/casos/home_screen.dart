import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/animal_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/case_card.dart';
import '../../widgets/petfind_header.dart';
import 'case_detail_screen.dart';
import 'create_case_screen.dart';

// RF-005 - Listar Casos Ativos (Figura 8)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _buscaController = TextEditingController();
  String? _especieFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  Future<void> _carregar() {
    return context.read<AnimalProvider>().carregarCasosAtivos(
          especie: _especieFiltro,
          nome: _buscaController.text.trim(),
        );
  }

  Future<void> _novoCaso() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCaseScreen()),
    );
    if (criado == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimalProvider>();

    return PetFindScaffold(
      titulo: 'Animais Perdidos',
      subtitulo: 'Casos ativos na sua região',
      mostrarVoltar: false,
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _buscaController,
                          decoration: const InputDecoration(hintText: 'Buscar por nome, raça...', prefixIcon: Icon(Icons.search)),
                          onSubmitted: (_) => _carregar(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: AppTheme.primaryButtonGradient), shape: BoxShape.circle),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _novoCaso,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chipEspecie('Cachorro', 'Cachorro'),
                        _chipEspecie('Gato', 'Gato'),
                        _chipEspecie(null, 'Todos'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(alignment: Alignment.centerLeft, child: SectionLabel('Próximos a você')),
            ),
            Expanded(child: _conteudo(provider)),
          ],
        ),
      ),
    );
  }

  Widget _chipEspecie(String? valor, String label) {
    final selecionado = _especieFiltro == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selecionado,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: selecionado ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        onSelected: (_) {
          setState(() => _especieFiltro = valor);
          _carregar();
        },
      ),
    );
  }

  Widget _conteudo(AnimalProvider provider) {
    if (provider.carregando && provider.casos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.erro != null) {
      return Center(child: Text(provider.erro!));
    }
    if (provider.casos.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 48),
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Nenhum animal perdido encontrado nesta região.', textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('Puxe para atualizar ou tente novamente mais tarde.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: provider.casos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final animal = provider.casos[index];
        return CaseCard(
          animal: animal,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CaseDetailScreen(animalId: animal.id)),
            );
            _carregar();
          },
        );
      },
    );
  }
}
