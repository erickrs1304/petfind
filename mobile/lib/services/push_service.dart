import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../data/api_client.dart';

// RF-008 - Notificações push via Firebase Cloud Messaging.
//
// Sem o google-services.json (projeto do Firebase não configurado) o Firebase não
// inicializa e o serviço fica desativado: o app segue funcionando, só sem push.
// Este arquivo não importa telas nem providers; quem usa registra os callbacks
// em configurar().
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _disponivel = false;
  String? _token;
  StreamSubscription<String>? _renovacao;

  void Function(int animalId)? _abrirCaso;
  void Function(String titulo, String corpo, int? animalId)? _aoReceberComAppAberto;
  int? _casoPendente;

  /// Define o que fazer ao tocar numa notificação e ao receber uma com o app aberto.
  void configurar({
    required void Function(int animalId) abrirCaso,
    required void Function(String titulo, String corpo, int? animalId) aoReceberComAppAberto,
  }) {
    _abrirCaso = abrirCaso;
    _aoReceberComAppAberto = aoReceberComAppAberto;
  }

  Future<void> iniciar() async {
    try {
      await Firebase.initializeApp();
      _disponivel = true;
    } catch (e) {
      debugPrint('Push desativado (Firebase não configurado): $e');
      return;
    }

    FirebaseMessaging.onMessage.listen((mensagem) {
      final notificacao = mensagem.notification;
      if (notificacao == null) return;
      _aoReceberComAppAberto?.call(notificacao.title ?? 'PetFind', notificacao.body ?? '', _animalId(mensagem));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_tocou);

    // App aberto direto pela notificação, estando fechado: o caso só pode ser
    // aberto depois do login restaurado (liberarPendente).
    final inicial = await FirebaseMessaging.instance.getInitialMessage();
    if (inicial != null) _casoPendente = _animalId(inicial);
  }

  int? _animalId(RemoteMessage mensagem) => int.tryParse('${mensagem.data['animalId'] ?? ''}');

  void _tocou(RemoteMessage mensagem) {
    final id = _animalId(mensagem);
    if (id != null) _abrirCaso?.call(id);
  }

  /// Depois do login: pede permissão, pega o token do celular e registra no servidor.
  Future<void> registrar() async {
    if (!_disponivel) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _enviarToken(token);
      _renovacao ??= FirebaseMessaging.instance.onTokenRefresh.listen(_enviarToken);
    } catch (e) {
      debugPrint('Não foi possível registrar o push: $e');
    }
  }

  Future<void> _enviarToken(String token) async {
    _token = token;
    await ApiClient.instance.dio.post('/devices', data: {'token': token});
  }

  /// Ao sair da conta: o celular deixa de receber os avisos de quem saiu.
  Future<void> remover() async {
    final token = _token;
    if (!_disponivel || token == null) return;
    try {
      await ApiClient.instance.dio.delete('/devices', queryParameters: {'token': token});
    } catch (e) {
      debugPrint('Não foi possível remover o token do servidor: $e');
    }
    _token = null;
  }

  /// Chamado quando a sessão está autenticada: abre o caso da notificação que
  /// iniciou o app, se houver.
  void liberarPendente() {
    final id = _casoPendente;
    if (id == null) return;
    _casoPendente = null;
    _abrirCaso?.call(id);
  }
}
