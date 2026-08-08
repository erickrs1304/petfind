import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Chip de status em formato pílula, como visto nos cards de caso e de
// avistamento do protótipo (ex.: "Desaparecido", "Confirmado"). O ícone
// varia por status (não só a cor), para não depender só de cor como
// portador de informação.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  (String, Color, Color, IconData) get _estilo {
    switch (status) {
      case 'ATIVO':
        return ('Desaparecido', AppTheme.primaryStrong.withValues(alpha: 0.15), AppTheme.primaryStrong, Icons.search);
      case 'ENCERRADO':
        return ('Encontrado', AppTheme.successStrong.withValues(alpha: 0.15), AppTheme.successStrong, Icons.check_circle);
      case 'CONFIRMADO':
        return ('Confirmado', AppTheme.successStrong.withValues(alpha: 0.15), AppTheme.successStrong, Icons.check_circle);
      case 'PENDENTE':
        return ('Pendente', AppTheme.primaryStrong.withValues(alpha: 0.15), AppTheme.primaryStrong, Icons.hourglass_top);
      case 'REJEITADO':
        return ('Excluído', Colors.grey.shade200, Colors.grey.shade700, Icons.cancel);
      default:
        return (status, Colors.grey.shade200, Colors.grey.shade700, Icons.circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (texto, corFundo, corTexto, icone) = _estilo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: corTexto),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(color: corTexto, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
