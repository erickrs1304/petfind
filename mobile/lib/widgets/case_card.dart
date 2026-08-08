import 'package:flutter/material.dart';

import '../data/models/animal.dart';
import '../theme/app_theme.dart';
import 'status_chip.dart';

class CaseCard extends StatelessWidget {
  const CaseCard({super.key, required this.animal, required this.onTap});

  final Animal animal;
  final VoidCallback onTap;

  IconData get _iconeEspecie {
    switch (animal.especie) {
      case 'Cachorro':
        return Icons.pets;
      case 'Gato':
        return Icons.cruelty_free;
      default:
        return Icons.emoji_nature;
    }
  }

  String get _tempoDesaparecido {
    final dias = DateTime.now().difference(animal.dataDesaparecimento).inDays;
    if (dias <= 0) return 'Desaparecido hoje';
    if (dias == 1) return 'Desaparecido há 1 dia';
    return 'Desaparecido há $dias dias';
  }

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
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                backgroundImage: animal.fotoUrlCompleta != null ? NetworkImage(animal.fotoUrlCompleta!) : null,
                child: animal.fotoUrlCompleta == null ? Icon(_iconeEspecie, color: AppTheme.primaryDark) : null,
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
                    Text(_subtitulo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (animal.distanciaKm != null)
                      Text(
                        '${animal.distanciaKm!.toStringAsFixed(1)} km de você',
                        style: const TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    Text(_tempoDesaparecido, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
