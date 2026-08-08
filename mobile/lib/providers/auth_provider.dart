import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models/usuario.dart';
import '../data/repositories/auth_repository.dart';

enum AuthStatus { carregando, autenticado, naoAutenticado }

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _carregarSessao();
  }

  final _repository = AuthRepository();

  AuthStatus status = AuthStatus.carregando;
  Usuario? usuario;

  Future<void> _carregarSessao() async {
    final token = await ApiClient.instance.readToken();
    if (token == null) {
      status = AuthStatus.naoAutenticado;
      notifyListeners();
      return;
    }
    try {
      usuario = await _repository.me();
      status = AuthStatus.autenticado;
    } catch (_) {
      await ApiClient.instance.clearToken();
      status = AuthStatus.naoAutenticado;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String senha}) async {
    usuario = await _repository.login(email: email, senha: senha);
    status = AuthStatus.autenticado;
    notifyListeners();
  }

  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    required String regiao,
    double? lat,
    double? lng,
  }) {
    return _repository.register(
      nome: nome,
      email: email,
      telefone: telefone,
      senha: senha,
      confirmarSenha: confirmarSenha,
      regiao: regiao,
      lat: lat,
      lng: lng,
    );
  }

  Future<String?> forgotPassword(String email) => _repository.forgotPassword(email: email);

  Future<void> resetPassword({
    required String email,
    required String codigo,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) {
    return _repository.resetPassword(
      email: email,
      codigo: codigo,
      novaSenha: novaSenha,
      confirmarNovaSenha: confirmarNovaSenha,
    );
  }

  Future<void> atualizarPerfil(Map<String, dynamic> dados) async {
    usuario = await _repository.updateProfile(dados);
    notifyListeners();
  }

  Future<void> logout() async {
    await _repository.logout();
    usuario = null;
    status = AuthStatus.naoAutenticado;
    notifyListeners();
  }
}
