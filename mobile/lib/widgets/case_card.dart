import 'package:flutter/material.dart';

import '../data/models/animal.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

class CaseCard extends StatelessWidget {
  const CaseCard({super.key, required this.animal, required this.onTap});

  final Animal animal;
  final VoidCallback onTap;

  // O Material Icons não tem gato (o ícone usado antes era um coelho): cão e gato usam a pata.
  IconData get _iconeEspecie => animal.especie == 'Outro' ? Icons.emoji_nature : Icons.pets;

  String get _subtitulo {
    final partes = [animal.especie, if (animal.porte != null && animal.porte!.isNotEmpty) animal.porte!, if (animal.raca != null && animal.raca!.isNotEmpty) animal.raca!];
    return partes.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryStrong.withValues(alpha: 0.12),
                ),
                child: animal.fotoUrlCompleta == null
                    ? Icon(_iconeEspecie, color: AppTheme.primaryStrong)
                    : Image.network(
                        animal.fotoUrlCompleta!,
                        fit: BoxFit.cover,
                        // Foto indisponível (ex.: arquivo antigo) volta ao ícone da espécie.
                        errorBuilder: (_, __, ___) => Icon(_iconeEspecie, color: AppTheme.primaryStrong),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(animal.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        StatusChip(status: animal.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_subtitulo, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (animal.distanciaKm != null)
                      Text(
                        '${animal.distanciaKm!.toStringAsFixed(1).replaceAll('.', ',')} km de você',
                        style: const TextStyle(color: AppTheme.primaryStrong, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    Text(formatarTempoDesaparecido(animal.dataDesaparecimento), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
