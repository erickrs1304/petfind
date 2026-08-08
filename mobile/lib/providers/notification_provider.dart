import 'package:flutter/material.dart';

import '../data/models/notificacao.dart';
import '../data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final _repository = NotificationRepository();

  List<Notificacao> notificacoes = [];
  bool carregando = false;

  int get naoLidas => notificacoes.where((n) => !n.lida).length;

  Future<void> carregar() async {
    carregando = true;
    notifyListeners();
    try {
      notificacoes = await _repository.listar();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> marcarComoLida(Notificacao notificacao) async {
    await _repository.marcarComoLida(notificacao.id);
    await carregar();
  }
}
