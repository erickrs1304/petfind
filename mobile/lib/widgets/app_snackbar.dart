import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppSnackType { success, error, info }

// Snackbar com cor/ícone de acordo com a severidade — evita que erros e
// sucessos apareçam com a mesma aparência neutra.
void showAppSnackBar(BuildContext context, String message, {AppSnackType type = AppSnackType.info}) {
  final (background, icon) = switch (type) {
    AppSnackType.success => (AppTheme.successStrong, Icons.check_circle_outline),
    AppSnackType.error => (AppTheme.dangerStrong, Icons.error_outline),
    AppSnackType.info => (Colors.black87, Icons.info_outline),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
    ),
  );
}
