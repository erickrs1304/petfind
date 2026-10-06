import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Área de seleção de foto com borda pontilhada laranja, como nas telas de
// "Publicar Animal" e "Registrar Avistamento" do protótipo.
// Recebe os bytes da imagem (em vez de um dart:io File) para funcionar tanto
// em mobile quanto na web.
class DashedPhotoPicker extends StatelessWidget {
  const DashedPhotoPicker({
    super.key,
    required this.onTap,
    this.fotoBytes,
    this.fotoUrl,
    this.texto = 'Adicionar foto',
    this.height = 140,
  });

  final VoidCallback onTap;
  final Uint8List? fotoBytes;

  /// Foto já salva no servidor, exibida na edição enquanto nenhuma nova é escolhida.
  final String? fotoUrl;

  final String texto;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bytes = fotoBytes;
    final ImageProvider? imagem = bytes != null
        ? MemoryImage(bytes)
        : (fotoUrl != null ? NetworkImage(fotoUrl!) : null);

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: imagem == null ? _DashedBorderPainter(color: AppTheme.primary) : null,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            image: imagem != null ? DecorationImage(image: imagem, fit: BoxFit.cover) : null,
          ),
          child: imagem == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryStrong.withValues(alpha: 0.15),
                      child: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryStrong),
                    ),
                    const SizedBox(height: 8),
                    Text(texto, style: const TextStyle(color: AppTheme.primaryStrong, fontWeight: FontWeight.w600)),
                    Text('Toque para selecionar', style: Theme.of(context).textTheme.bodySmall),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    final path = Path()..addRRect(rrect);
    final dashed = _dashPath(path, dashLength: 6, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final next = math.min(distance + length, metric.length);
        if (draw) dest.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
