import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_snackbar.dart';
import 'constants.dart';

// A Google Play exige que a política de privacidade possa ser aberta de dentro do app.
Future<void> abrirPoliticaPrivacidade(BuildContext context) async {
  var abriu = false;
  try {
    abriu = await launchUrl(Uri.parse(kPoliticaPrivacidadeUrl), mode: LaunchMode.externalApplication);
  } catch (_) {
    abriu = false;
  }
  if (!abriu && context.mounted) {
    showAppSnackBar(context, 'Não foi possível abrir a política de privacidade.', type: AppSnackType.error);
  }
}
