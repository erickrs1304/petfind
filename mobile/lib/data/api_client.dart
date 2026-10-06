import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(BaseOptions(baseUrl: kApiBaseUrl, connectTimeout: const Duration(seconds: 10)));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Token recusado pelo servidor (expirado, ou usuário removido do banco):
          // descarta a sessão local em vez de deixar o app preso num estado zumbi,
          // "logado" mas com todas as ações falhando.
          final enviouToken = error.requestOptions.headers.containsKey('Authorization');
          if (error.response?.statusCode == 401 && enviouToken) {
            await clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();
  static const _tokenKey = 'petfind_token';
  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  /// Chamado quando o servidor recusa o token — o AuthProvider usa isso para
  /// devolver o usuário à tela de login.
  void Function()? onUnauthorized;

  Dio get dio => _dio;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}

// Extrai uma mensagem de erro amigável de uma DioException, usando a mensagem
// enviada pela API quando disponível (ex.: "E-mail ou senha inválidos.").
String extractErrorMessage(Object error, {String fallback = 'Não foi possível completar a operação.'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    // Sem resposta do servidor não há o que validar: dizer só "não foi possível"
    // faz parecer que os dados foram recusados, quando na verdade a API está
    // inacessível (back-end parado, IP errado, sem rede).
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Não foi possível falar com o servidor ($kApiBaseUrl). '
            'Verifique se o back-end está rodando e se você está na mesma rede.';
      default:
        break;
    }
  }
  return fallback;
}
