import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/animal.dart';
import '../data/repositories/animal_repository.dart';
import '../utils/constants.dart';

/// De onde veio a coordenada usada para ordenar/filtrar a listagem (RF-005 A2).
enum OrigemLocalizacao {
  /// GPS do aparelho — resultado mais preciso.
  gps,

  /// Região cadastrada no perfil, usada quando o GPS não está disponível.
  perfil,

  /// Nenhuma coordenada conhecida: a lista vem sem distância e sem ordenação.
  indisponivel,
}

class AnimalProvider extends ChangeNotifier {
  final _repository = AnimalRepository();

  List<Animal> casos = [];
  bool carregando = false;
  String? erro;
  Position? ultimaPosicao;
  OrigemLocalizacao origemLocalizacao = OrigemLocalizacao.indisponivel;

  /// Raio da busca em km. Começa no padrão do DERS (5km) e cresce quando o
  /// usuário aciona "Ampliar busca" (RF-005 A1).
  double raioKm = kDefaultNotificationRadiusKm;

  double? _lat;
  double? _lng;

  bool get usandoRegiaoDoPerfil => origemLocalizacao == OrigemLocalizacao.perfil;

  /// Carrega os casos ativos ordenados por proximidade. [perfilLat]/[perfilLng]
  /// são as coordenadas da região cadastrada no perfil, usadas como plano B
  /// quando o GPS está indisponível ou sem permissão (RF-005 A2).
  Future<void> carregarCasosAtivos({
    String? especie,
    String? nome,
    double? perfilLat,
    double? perfilLng,
  }) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      await _resolverLocalizacao(perfilLat: perfilLat, perfilLng: perfilLng);
      casos = await _repository.listarAtivos(
        lat: _lat,
        lng: _lng,
        especie: especie,
        nome: nome,
        raioKm: _lat != null ? raioKm : null,
      );
    } catch (e) {
      erro = 'Não foi possível carregar os casos. Verifique sua conexão.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  /// RF-005 A1 - dobra o raio de busca e recarrega a listagem.
  Future<void> ampliarBusca({String? especie, String? nome, double? perfilLat, double? perfilLng}) {
    raioKm *= 2;
    return carregarCasosAtivos(
      especie: especie,
      nome: nome,
      perfilLat: perfilLat,
      perfilLng: perfilLng,
    );
  }

  Future<void> _resolverLocalizacao({double? perfilLat, double? perfilLng}) async {
    ultimaPosicao ??= await _obterPosicaoAtual();

    if (ultimaPosicao != null) {
      _lat = ultimaPosicao!.latitude;
      _lng = ultimaPosicao!.longitude;
      origemLocalizacao = OrigemLocalizacao.gps;
      return;
    }

    if (perfilLat != null && perfilLng != null) {
      _lat = perfilLat;
      _lng = perfilLng;
      origemLocalizacao = OrigemLocalizacao.perfil;
      return;
    }

    _lat = null;
    _lng = null;
    origemLocalizacao = OrigemLocalizacao.indisponivel;
  }

  Future<Position?> _obterPosicaoAtual() async {
    try {
      final habilitado = await Geolocator.isLocationServiceEnabled();
      if (!habilitado) return null;

      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position> obterPosicaoObrigatoria() async {
    final posicao = await _obterPosicaoAtual();
    if (posicao == null) {
      throw Exception('Não foi possível obter sua localização. Ative o GPS e tente novamente.');
    }
    return posicao;
  }
}
