import '../api_client.dart';
import '../models/usuario.dart';

class AuthRepository {
  final _dio = ApiClient.instance.dio;

  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
    required String confirmarSenha,
    required String regiao,
    required bool notificacoesAtivas,
    double? lat,
    double? lng,
  }) async {
    await _dio.post('/auth/register', data: {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'senha': senha,
      'confirmarSenha': confirmarSenha,
      'regiao': regiao,
      'notificacoesAtivas': notificacoesAtivas,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
  }

  Future<Usuario> login({required String email, required String senha}) async {
    final response = await _dio.post('/auth/login', data: {'email': email, 'senha': senha});
    final token = response.data['token'] as String;
    await ApiClient.instance.saveToken(token);
    return Usuario.fromJson(response.data['usuario'] as Map<String, dynamic>);
  }

  Future<void> logout() => ApiClient.instance.clearToken();

  Future<String?> forgotPassword({required String email}) async {
    final response = await _dio.post('/auth/forgot-password', data: {'email': email});
    return response.data['devCode'] as String?;
  }

  Future<void> resetPassword({
    required String email,
    required String codigo,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'email': email,
      'codigo': codigo,
      'novaSenha': novaSenha,
      'confirmarNovaSenha': confirmarNovaSenha,
    });
  }

  Future<Usuario> me() async {
    final response = await _dio.get('/auth/me');
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Usuario> updateProfile(Map<String, dynamic> dados) async {
    final response = await _dio.put('/auth/me', data: dados);
    return Usuario.fromJson(response.data as Map<String, dynamic>);
  }

  /// RF-001 - exclusão da conta; o servidor exige a senha como confirmação.
  Future<void> excluirConta({required String senha}) => _dio.delete('/auth/me', data: {'senha': senha});
}
