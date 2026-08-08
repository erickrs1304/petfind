import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Chip de status em formato pílula, como visto nos cards de caso e de
// avistamento do protótipo (ex.: "Desaparecido", "Confirmado").
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  (String, Color, Color) get _estilo {
    switch (status) {
      case 'ATIVO':
        return ('Desaparecido', AppTheme.primary.withValues(alpha: 0.15), AppTheme.primaryDark);
      case 'ENCERRADO':
        return ('Encontrado', AppTheme.success.withValues(alpha: 0.15), AppTheme.success);
      case 'CONFIRMADO':
        return ('Confirmado', AppTheme.success.withValues(alpha: 0.15), AppTheme.success);
      case 'PENDENTE':
        return ('Pendente', AppTheme.primary.withValues(alpha: 0.15), AppTheme.primaryDark);
      case 'REJEITADO':
        return ('Excluído', Colors.grey.shade200, Colors.grey.shade700);
      default:
        return (status, Colors.grey.shade200, Colors.grey.shade700);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (texto, corFundo, corTexto) = _estilo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: corFundo, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: corTexto),
          const SizedBox(width: 6),
          Text(texto, style: TextStyle(color: corTexto, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
