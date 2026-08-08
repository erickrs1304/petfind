import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/animal.dart';
import '../data/repositories/animal_repository.dart';

class AnimalProvider extends ChangeNotifier {
  final _repository = AnimalRepository();

  List<Animal> casos = [];
  bool carregando = false;
  String? erro;
  Position? ultimaPosicao;

  Future<void> carregarCasosAtivos({String? especie, String? nome}) async {
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      ultimaPosicao ??= await _obterPosicaoAtual();
      casos = await _repository.listarAtivos(
        lat: ultimaPosicao?.latitude,
        lng: ultimaPosicao?.longitude,
        especie: especie,
        nome: nome,
      );
    } catch (e) {
      erro = 'Não foi possível carregar os casos. Verifique sua conexão.';
    } finally {
      carregando = false;
      notifyListeners();
    }
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
