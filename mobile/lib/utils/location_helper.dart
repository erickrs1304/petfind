import 'package:geolocator/geolocator.dart';

import '../services/push_service.dart';

// Erro amigável (já traduzido para o usuário) lançado por obterLocalizacaoAtual().
class LocalizacaoException implements Exception {
  const LocalizacaoException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _mensagemPadrao = 'Não foi possível obter sua localização. Ative o GPS e tente novamente.';

Future<LocationPermission>? _pedidoEmAndamento;

// Pede a permissão de localização, se ainda não foi dada. O Android mostra um pedido por vez:
// espera o de notificações (feito logo após o login) e reaproveita um pedido de localização já
// aberto. Antes, o segundo pedido se perdia e a lista de casos ficava carregando para sempre.
Future<LocationPermission> pedirPermissaoDeLocalizacao() async {
  final atual = await Geolocator.checkPermission();
  if (atual != LocationPermission.denied) return atual;
  await PushService.instance.aguardarPedidoDeNotificacoes();
  return _pedidoEmAndamento ??= Geolocator.requestPermission().whenComplete(() => _pedidoEmAndamento = null);
}

// Obtém a posição GPS atual, checando serviço de localização e permissão
// antes de tentar capturar. Lança LocalizacaoException com mensagem amigável
// em qualquer ponto de falha (serviço desligado, permissão negada, timeout).
Future<Position> obterLocalizacaoAtual() async {
  final habilitado = await Geolocator.isLocationServiceEnabled();
  if (!habilitado) throw const LocalizacaoException(_mensagemPadrao);

  final permissao = await pedirPermissaoDeLocalizacao();
  if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
    throw const LocalizacaoException(_mensagemPadrao);
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  } catch (_) {
    throw const LocalizacaoException(_mensagemPadrao);
  }
}
