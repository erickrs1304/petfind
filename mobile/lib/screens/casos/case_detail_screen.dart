import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/repositories/animal_repository.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/share_helper.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import '../avistamentos/confirm_sightings_screen.dart';
import '../avistamentos/map_screen.dart';
import '../avistamentos/register_sighting_screen.dart';
import 'close_case_screen.dart';
import 'create_case_screen.dart';

// Tela de detalhes do caso: ponto de entrada para RF-006, RF-007, RF-009 e RF-010.
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.animalId});

  final int animalId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final _repository = AnimalRepository();
  Animal? _animal;
  int _totalAvistamentos = 0;
  int _avistamentosPendentes = 0;
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
      final animal = await _repository.buscarPorId(widget.animalId);
      final avistamentos = await _repository.listarAvistamentos(widget.animalId);
      setState(() {
        _animal = animal;
        _totalAvistamentos = avistamentos.length;
        _avistamentosPendentes = avistamentos.where((a) => a.status == 'PENDENTE').length;
      });
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível carregar o caso.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _irParaEncerrarCaso() async {
    final encerrado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CloseCaseScreen(animal: _animal!, totalAvistamentos: _totalAvistamentos)),
    );
    if (encerrado == true) _carregar();
  }

  // RF-004 (3.2) - edição do caso pelo tutor.
  Future<void> _editarCaso() async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateCaseScreen(animalParaEditar: _animal!)),
    );
    if (salvo == true) _carregar();
  }

  Future<void> _revisarAvistamentos() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ConfirmSightingsScreen(animal: _animal!)),
    );
    if (mounted) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final animal = _animal;
    final ehTutor = usuario != null && animal != null && usuario.id == animal.usuarioId;

    return PetFindScaffold(
      titulo: animal?.nome ?? 'Detalhes do caso',
      subtitulo: animal != null ? '${animal.especie} • $_totalAvistamentos avistamentos' : null,
      acoes: [
        if (animal != null)
          IconButton(
            tooltip: 'Compartilhar caso',
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => compartilharCaso(animal),
          ),
      ],
      body: _carregando
          ? const LoadingView()
          : _erro != null
              ? ErrorView(message: _erro!, onRetry: _carregar)
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (animal!.fotoUrlCompleta != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(animal.fotoUrlCompleta!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: Text(animal.nome, style: Theme.of(context).textTheme.headlineSmall)),
                          StatusChip(status: animal.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _linha(context, 'Espécie', animal.especie),
                      if (animal.raca != null && animal.raca!.isNotEmpty) _linha(context, 'Raça', animal.raca!),
                      if (animal.porte != null && animal.porte!.isNotEmpty) _linha(context, 'Porte', animal.porte!),
                      _linha(context, 'Características', animal.caracteristicas),
                      _linha(context, 'Última localização', animal.ultimaLocalizacaoTexto),
                      _linha(context, 'Desaparecido em', formatarData(animal.dataDesaparecimento)),
                      if (animal.tutorNome != null) _linha(context, 'Tutor', animal.tutorNome!),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MapScreen(animal: animal)),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver mapa e trajetória'),
                      ),
                      const SizedBox(height: 12),
                      if (!ehTutor && animal.ativo)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final registrado = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => RegisterSightingScreen(animal: animal)),
                            );
                            if (registrado == true) _carregar();
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Registrar avistamento'),
                        ),
                      if (ehTutor && animal.ativo) ...[
                        const InfoBanner(
                          message: 'Você é o tutor deste caso — por isso não é possível registrar um avistamento aqui. '
                              'Se encontrou o animal, use "Animal encontrado!" abaixo para encerrar a busca.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _editarCaso,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar caso'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _revisarAvistamentos,
                          icon: const Icon(Icons.playlist_add_check_outlined),
                          label: Text(
                            _avistamentosPendentes > 0
                                ? 'Confirmar/excluir avistamentos ($_avistamentosPendentes pendentes)'
                                : 'Confirmar/excluir avistamentos',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _irParaEncerrarCaso,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successStrong),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Animal encontrado!'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _linha(BuildContext context, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
          Text(valor),
        ],
      ),
    );
  }
}
