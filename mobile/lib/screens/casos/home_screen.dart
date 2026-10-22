import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/animal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/case_card.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';
import 'case_detail_screen.dart';
import 'create_case_screen.dart';
import 'my_cases_screen.dart';

// RF-005 - Listar Casos Ativos (Figura 8)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _buscaController = TextEditingController();
  String? _especieFiltro;
  Timer? _debounceBusca;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _debounceBusca?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  // RF-005 A3 - a lista acompanha a digitação; o debounce evita uma requisição
  // por tecla pressionada.
  void _aoDigitarBusca(String _) {
    _debounceBusca?.cancel();
    _debounceBusca = Timer(const Duration(milliseconds: 400), _carregar);
  }

  Future<void> _carregar() {
    final usuario = context.read<AuthProvider>().usuario;
    return context.read<AnimalProvider>().carregarCasosAtivos(
          especie: _especieFiltro,
          nome: _buscaController.text.trim(),
          perfilLat: usuario?.lat,
          perfilLng: usuario?.lng,
        );
  }

  // RF-005 A1 - amplia o raio quando nada é encontrado na região atual.
  Future<void> _ampliarBusca() {
    final usuario = context.read<AuthProvider>().usuario;
    return context.read<AnimalProvider>().ampliarBusca(
          especie: _especieFiltro,
          nome: _buscaController.text.trim(),
          perfilLat: usuario?.lat,
          perfilLng: usuario?.lng,
        );
  }

  Future<void> _novoCaso() async {
    final criado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateCaseScreen()),
    );
    if (criado == true) _carregar();
  }

  Future<void> _abrirMeusCasos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyCasesScreen()),
    );
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnimalProvider>();

    return PetFindScaffold(
      titulo: 'Animais Perdidos',
      subtitulo: 'Casos ativos na sua região',
      mostrarVoltar: false,
      acoes: [
        IconButton(
          tooltip: 'Meus casos',
          icon: const Icon(Icons.folder_shared_outlined, color: Colors.white),
          onPressed: _abrirMeusCasos,
        ),
      ],
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
                          decoration: const InputDecoration(hintText: 'Buscar por nome...', prefixIcon: Icon(Icons.search)),
                          onChanged: _aoDigitarBusca,
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
                        _chipEspecie('Outro', 'Outro'),
                        _chipEspecie(null, 'Todos'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // RF-005 A2 - sem GPS, a busca cai para a localização salva no perfil (alertas
            // ligados); sem nenhuma das duas, a lista mostra todos os casos, sem distância.
            if (provider.usandoRegiaoDoPerfil || provider.semLocalizacao)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: InfoBanner(
                  icon: Icons.location_off_outlined,
                  message: provider.semLocalizacao
                      ? 'Ative a localização para ver os casos mais próximos de você.'
                      : 'Usando região do seu perfil. Ative o GPS para resultados mais precisos.',
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SectionLabel(provider.semLocalizacao
                    ? 'Casos ativos'
                    : 'Próximos a você • ${provider.raioKm.toStringAsFixed(0)} km'),
              ),
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
        selectedColor: AppTheme.primaryStrong,
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
      return const LoadingView();
    }
    if (provider.erro != null) {
      return ErrorView(message: provider.erro!, onRetry: _carregar);
    }
    if (provider.casos.isEmpty) {
      // RF-005 A1 - além do aviso, oferece ampliar o raio e dicas de como ajudar.
      final temLocalizacao = provider.origemLocalizacao != OrigemLocalizacao.indisponivel;
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: EmptyView(
          icon: Icons.search_off,
          title: 'Nenhum animal perdido encontrado nesta região.',
          subtitle: temLocalizacao
              ? 'Nenhum caso ativo em um raio de ${provider.raioKm.toStringAsFixed(0)} km de você.'
              : 'Puxe para atualizar ou seja o primeiro a cadastrar um caso.',
          actionLabel: temLocalizacao ? 'Ampliar busca' : null,
          onAction: temLocalizacao ? _ampliarBusca : null,
          secondaryActionLabel: 'Cadastrar caso',
          onSecondaryAction: _novoCaso,
          footer: const _DicasComoAjudar(),
        ),
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

// RF-005 A1 (c) - dicas sobre como ajudar, exibidas quando não há casos na região.
class _DicasComoAjudar extends StatelessWidget {
  const _DicasComoAjudar();

  static const _dicas = [
    'Compartilhe os casos ativos com vizinhos e grupos do bairro.',
    'Ao ver um animal perdido, registre o avistamento com o GPS ligado.',
    'Mantenha as notificações por proximidade ativas para ser avisado na hora.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Como ajudar'),
          for (final dica in _dicas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.volunteer_activism_outlined, size: 16, color: AppTheme.primaryStrong),
                  const SizedBox(width: 8),
                  Expanded(child: Text(dica, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
