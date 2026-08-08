import '../api_client.dart';
import '../models/notificacao.dart';

class NotificationRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Notificacao>> listar() async {
    final response = await _dio.get('/notifications');
    return (response.data as List).map((e) => Notificacao.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> marcarComoLida(int id) async {
    await _dio.post('/notifications/$id/read');
  }
}
