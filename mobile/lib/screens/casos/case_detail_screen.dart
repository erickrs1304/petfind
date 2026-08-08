import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/repositories/animal_repository.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/status_chip.dart';
import '../avistamentos/confirm_sightings_screen.dart';
import '../avistamentos/map_screen.dart';
import '../avistamentos/register_sighting_screen.dart';
import 'close_case_screen.dart';

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
      final animal = await _repository.buscarPorId(widget.animalId);
      final avistamentos = await _repository.listarAvistamentos(widget.animalId);
      _animal = animal;
      _totalAvistamentos = avistamentos.length;
    } catch (e) {
      _erro = extractErrorMessage(e, fallback: 'Não foi possível carregar o caso.');
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

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario;
    final ehTutor = usuario != null && _animal != null && usuario.id == _animal!.usuarioId;

    return Scaffold(
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : Column(
                  children: [
                    PetFindHeader(titulo: _animal!.nome, subtitulo: '${_animal!.especie} • $_totalAvistamentos avistamentos'),
                    Expanded(
                      child: Container(
                        color: AppTheme.background,
                        child: RefreshIndicator(
                          onRefresh: _carregar,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_animal!.fotoUrlCompleta != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(_animal!.fotoUrlCompleta!, height: 200, width: double.infinity, fit: BoxFit.cover),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Text(_animal!.nome, style: Theme.of(context).textTheme.headlineSmall)),
                                  StatusChip(status: _animal!.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _linha('Espécie', _animal!.especie),
                              if (_animal!.raca != null && _animal!.raca!.isNotEmpty) _linha('Raça', _animal!.raca!),
                              if (_animal!.porte != null && _animal!.porte!.isNotEmpty) _linha('Porte', _animal!.porte!),
                              _linha('Características', _animal!.caracteristicas),
                              _linha('Última localização', _animal!.ultimaLocalizacaoTexto),
                              _linha('Desaparecido em',
                                  '${_animal!.dataDesaparecimento.day}/${_animal!.dataDesaparecimento.month}/${_animal!.dataDesaparecimento.year}'),
                              if (_animal!.tutorNome != null) _linha('Tutor', _animal!.tutorNome!),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => MapScreen(animal: _animal!)),
                                ),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Ver mapa e trajetória'),
                              ),
                              const SizedBox(height: 12),
                              if (_animal!.ativo)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final registrado = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(builder: (_) => RegisterSightingScreen(animal: _animal!)),
                                    );
                                    if (registrado == true) _carregar();
                                  },
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Registrar avistamento'),
                                ),
                              if (ehTutor && _animal!.ativo) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ConfirmSightingsScreen(animal: _animal!)),
                                  ),
                                  icon: const Icon(Icons.playlist_add_check_outlined),
                                  label: const Text('Confirmar/excluir avistamentos'),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _irParaEncerrarCaso,
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Animal encontrado!'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rotulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(valor),
        ],
      ),
    );
  }
}
