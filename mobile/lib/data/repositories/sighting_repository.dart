import '../api_client.dart';

class SightingRepository {
  final _dio = ApiClient.instance.dio;

  Future<void> confirmar(int avistamentoId, {String? comentario}) async {
    await _dio.post('/sightings/$avistamentoId/confirm', data: {
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    });
  }

  Future<void> excluir(int avistamentoId) async {
    await _dio.post('/sightings/$avistamentoId/reject');
  }
}
