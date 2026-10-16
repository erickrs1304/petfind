import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/animal.dart';
import '../models/avistamento.dart';
import '../models/picked_photo.dart';

class AnimalRepository {
  final _dio = ApiClient.instance.dio;

  Future<List<Animal>> listarAtivos({
    double? lat,
    double? lng,
    String? especie,
    String? nome,
    double? raioKm,
  }) async {
    final response = await _dio.get('/animals', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (especie != null && especie.isNotEmpty) 'especie': especie,
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (raioKm != null) 'raioKm': raioKm,
    });
    return (response.data as List).map((e) => Animal.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Casos do tutor logado — usado na tela "Meus Casos" (RF-004 edição, RF-009 histórico).
  /// [status] aceita 'ATIVO', 'ENCERRADO' ou 'TODOS'.
  Future<List<Animal>> listarMeusCasos({required String status}) async {
    final response = await _dio.get('/animals', queryParameters: {
      'meus': 'true',
      'status': status,
    });
    return (response.data as List).map((e) => Animal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Animal> buscarPorId(int id) async {
    final response = await _dio.get('/animals/$id');
    return Animal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Animal> criar({
    required String nome,
    required String especie,
    String? raca,
    String? porte,
    required String caracteristicas,
    required DateTime dataDesaparecimento,
    required String ultimaLocalizacaoTexto,
    required double lat,
    required double lng,
    PickedPhoto? foto,
  }) async {
    final formData = FormData.fromMap({
      'nome': nome,
      'especie': especie,
      if (raca != null && raca.isNotEmpty) 'raca': raca,
      if (porte != null && porte.isNotEmpty) 'porte': porte,
      'caracteristicas': caracteristicas,
      'dataDesaparecimento': dataDesaparecimento.toIso8601String().substring(0, 10),
      'ultimaLocalizacaoTexto': ultimaLocalizacaoTexto,
      'lat': lat,
      'lng': lng,
      if (foto != null) 'foto': MultipartFile.fromBytes(foto.bytes, filename: foto.filename),
    });
    final response = await _dio.post('/animals', data: formData);
    return Animal.fromJson(response.data as Map<String, dynamic>);
  }

  /// RF-004 - edição do caso. Só envia os campos preenchidos; a foto é opcional
  /// (se não vier uma nova, o back-end mantém a atual).
  Future<Animal> editar({
    required int id,
    required String nome,
    required String especie,
    String? raca,
    String? porte,
    required String caracteristicas,
    required DateTime dataDesaparecimento,
    required String ultimaLocalizacaoTexto,
    required double lat,
    required double lng,
    PickedPhoto? foto,
  }) async {
    final formData = FormData.fromMap({
      'nome': nome,
      'especie': especie,
      if (raca != null && raca.isNotEmpty) 'raca': raca,
      if (porte != null && porte.isNotEmpty) 'porte': porte,
      'caracteristicas': caracteristicas,
      'dataDesaparecimento': dataDesaparecimento.toIso8601String().substring(0, 10),
      'ultimaLocalizacaoTexto': ultimaLocalizacaoTexto,
      'lat': lat,
      'lng': lng,
      if (foto != null) 'foto': MultipartFile.fromBytes(foto.bytes, filename: foto.filename),
    });
    final response = await _dio.put('/animals/$id', data: formData);
    return Animal.fromJson(response.data as Map<String, dynamic>);
  }

  /// RF-004 - exclusão do caso pelo tutor (apaga também os avistamentos e as fotos).
  Future<void> excluir(int id) => _dio.delete('/animals/$id');

  Future<Animal> encerrarCaso(int id) async {
    final response = await _dio.post('/animals/$id/close');
    return Animal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Avistamento> registrarAvistamento({
    required int animalId,
    required double lat,
    required double lng,
    String? comentario,
    PickedPhoto? foto,
  }) async {
    final formData = FormData.fromMap({
      'lat': lat,
      'lng': lng,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      if (foto != null) 'foto': MultipartFile.fromBytes(foto.bytes, filename: foto.filename),
    });
    final response = await _dio.post('/animals/$animalId/sightings', data: formData);
    return Avistamento.fromJson(response.data['avistamento'] as Map<String, dynamic>);
  }

  Future<List<Avistamento>> listarAvistamentos(int animalId, {String? status}) async {
    final response = await _dio.get(
      '/animals/$animalId/sightings',
      queryParameters: {if (status != null) 'status': status},
    );
    return (response.data as List).map((e) => Avistamento.fromJson(e as Map<String, dynamic>)).toList();
  }
}
