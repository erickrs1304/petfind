import 'package:flutter_test/flutter_test.dart';
import 'package:petfind/data/models/animal.dart';
import 'package:petfind/data/models/avistamento.dart';
import 'package:petfind/data/models/usuario.dart';

// Teste unitário puro (sem widget/UI): exercita o parsing fromJson dos
// modelos de dados, incluindo campos aninhados e valores-padrão.
void main() {
  group('Animal.fromJson', () {
    test('faz o parsing de um caso completo, incluindo o nome do tutor aninhado', () {
      final animal = Animal.fromJson({
        'id': 1,
        'usuarioId': 10,
        'nome': 'Rex',
        'especie': 'Cachorro',
        'porte': 'Médio',
        'caracteristicas': 'Coleira azul',
        'dataDesaparecimento': '2026-01-10',
        'ultimaLocalizacaoTexto': 'Praça Central',
        'lat': -17.7929,
        'lng': -50.9188,
        'status': 'ATIVO',
        'distanciaKm': 1.5,
        'tutor': {'id': 10, 'nome': 'Erick'},
      });

      expect(animal.nome, 'Rex');
      expect(animal.tutorNome, 'Erick');
      expect(animal.ativo, isTrue);
      expect(animal.distanciaKm, 1.5);
    });

    test('trata tutor ausente e status encerrado', () {
      final animal = Animal.fromJson({
        'id': 2,
        'usuarioId': 10,
        'nome': 'Mia',
        'especie': 'Gato',
        'caracteristicas': 'Pelo branco',
        'dataDesaparecimento': '2026-01-01',
        'ultimaLocalizacaoTexto': 'Rua A',
        'lat': -17.79,
        'lng': -50.91,
        'status': 'ENCERRADO',
      });

      expect(animal.tutorNome, isNull);
      expect(animal.ativo, isFalse);
    });

    test('fotoUrlCompleta é nula quando fotoUrl é nulo, e concatena a base da API quando presente', () {
      final semFoto = Animal.fromJson({
        'id': 3,
        'usuarioId': 10,
        'nome': 'Rex',
        'especie': 'Cachorro',
        'caracteristicas': 'x',
        'dataDesaparecimento': '2026-01-01',
        'ultimaLocalizacaoTexto': 'x',
        'lat': 0,
        'lng': 0,
        'status': 'ATIVO',
      });
      expect(semFoto.fotoUrlCompleta, isNull);

      final comFoto = Animal.fromJson({
        'id': 4,
        'usuarioId': 10,
        'nome': 'Rex',
        'especie': 'Cachorro',
        'caracteristicas': 'x',
        'dataDesaparecimento': '2026-01-01',
        'ultimaLocalizacaoTexto': 'x',
        'lat': 0,
        'lng': 0,
        'status': 'ATIVO',
        'fotoUrl': '/uploads/foto1.jpg',
      });
      expect(comFoto.fotoUrlCompleta, endsWith('/uploads/foto1.jpg'));
    });
  });

  group('Avistamento.fromJson', () {
    test('faz o parsing incluindo o nome do colaborador aninhado', () {
      final avistamento = Avistamento.fromJson({
        'id': 1,
        'animalId': 5,
        'usuarioId': 20,
        'lat': -17.79,
        'lng': -50.91,
        'dataHora': '2026-02-01T10:00:00.000Z',
        'status': 'CONFIRMADO',
        'colaborador': {'id': 20, 'nome': 'João'},
      });

      expect(avistamento.status, 'CONFIRMADO');
      expect(avistamento.colaboradorNome, 'João');
    });

    test('trata colaborador ausente e comentário nulo', () {
      final avistamento = Avistamento.fromJson({
        'id': 2,
        'animalId': 5,
        'usuarioId': 20,
        'lat': -17.79,
        'lng': -50.91,
        'dataHora': '2026-02-01T10:00:00.000Z',
        'status': 'PENDENTE',
      });

      expect(avistamento.colaboradorNome, isNull);
      expect(avistamento.comentario, isNull);
    });
  });

  group('Usuario.fromJson', () {
    test('aplica os valores-padrão quando raioNotificacaoKm e notificacoesAtivas estão ausentes', () {
      final usuario = Usuario.fromJson({
        'id': 1,
        'nome': 'Erick',
        'email': 'erick@example.com',
        'regiao': 'Rio Verde - GO',
      });

      expect(usuario.raioNotificacaoKm, 5);
      expect(usuario.notificacoesAtivas, isTrue);
    });

    test('usa os valores explícitos quando presentes', () {
      final usuario = Usuario.fromJson({
        'id': 1,
        'nome': 'Erick',
        'email': 'erick@example.com',
        'regiao': 'Rio Verde - GO',
        'raioNotificacaoKm': 10,
        'notificacoesAtivas': false,
      });

      expect(usuario.raioNotificacaoKm, 10);
      expect(usuario.notificacoesAtivas, isFalse);
    });
  });
}
