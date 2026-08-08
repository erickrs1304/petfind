import 'package:geolocator/geolocator.dart';

// Erro amigável (já traduzido para o usuário) lançado por obterLocalizacaoAtual().
class LocalizacaoException implements Exception {
  const LocalizacaoException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _mensagemPadrao = 'Não foi possível obter sua localização. Ative o GPS e tente novamente.';

// Obtém a posição GPS atual, checando serviço de localização e permissão
// antes de tentar capturar. Lança LocalizacaoException com mensagem amigável
// em qualquer ponto de falha (serviço desligado, permissão negada, timeout).
Future<Position> obterLocalizacaoAtual() async {
  final habilitado = await Geolocator.isLocationServiceEnabled();
  if (!habilitado) throw const LocalizacaoException(_mensagemPadrao);

  var permissao = await Geolocator.checkPermission();
  if (permissao == LocationPermission.denied) {
    permissao = await Geolocator.requestPermission();
  }
  if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
    throw const LocalizacaoException(_mensagemPadrao);
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  } catch (_) {
    throw const LocalizacaoException(_mensagemPadrao);
  }
}
