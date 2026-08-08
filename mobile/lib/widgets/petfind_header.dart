import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Cabeçalho laranja com cantos arredondados na base, título e subtítulo,
// reproduzindo o padrão visual presente em todas as telas do protótipo do TCC.
class PetFindHeader extends StatelessWidget {
  const PetFindHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.mostrarVoltar = true,
    this.acoes = const [],
  });

  final String titulo;
  final String? subtitulo;
  final bool mostrarVoltar;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.headerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Row(
        children: [
          if (mostrarVoltar)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.15)),
            ),
          if (mostrarVoltar) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (subtitulo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitulo!, style: TextStyle(color: Colors.white.withValues(alpha: 0.9))),
                  ),
              ],
            ),
          ),
          ...acoes,
        ],
      ),
    );
  }
}

// Scaffold padrão do app: cabeçalho fixo no topo + conteúdo scrollável em
// um card branco arredondado sobreposto, como no protótipo.
class PetFindScaffold extends StatelessWidget {
  const PetFindScaffold({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.mostrarVoltar = true,
    this.acoes = const [],
    required this.body,
    this.floatingActionButton,
    this.scrollable = true,
  });

  final String titulo;
  final String? subtitulo;
  final bool mostrarVoltar;
  final List<Widget> acoes;
  final Widget body;
  final Widget? floatingActionButton;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          PetFindHeader(titulo: titulo, subtitulo: subtitulo, mostrarVoltar: mostrarVoltar, acoes: acoes),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppTheme.background,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
