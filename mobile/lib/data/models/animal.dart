import '../../utils/constants.dart';

class Animal {
  Animal({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.especie,
    this.raca,
    this.porte,
    required this.caracteristicas,
    this.fotoUrl,
    required this.dataDesaparecimento,
    required this.ultimaLocalizacaoTexto,
    required this.lat,
    required this.lng,
    required this.status,
    this.distanciaKm,
    this.tutorNome,
  });

  final int id;
  final int usuarioId;
  final String nome;
  final String especie;
  final String? raca;
  final String? porte;
  final String caracteristicas;
  final String? fotoUrl;
  final DateTime dataDesaparecimento;
  final String ultimaLocalizacaoTexto;
  final double lat;
  final double lng;
  final String status;
  final double? distanciaKm;
  final String? tutorNome;

  bool get ativo => status == 'ATIVO';

  String? get fotoUrlCompleta => fotoUrl == null ? null : '$kApiBaseUrl$fotoUrl';

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: json['id'] as int,
        usuarioId: json['usuarioId'] as int,
        nome: json['nome'] as String,
        especie: json['especie'] as String,
        raca: json['raca'] as String?,
        porte: json['porte'] as String?,
        caracteristicas: json['caracteristicas'] as String,
        fotoUrl: json['fotoUrl'] as String?,
        dataDesaparecimento: DateTime.parse(json['dataDesaparecimento'] as String),
        ultimaLocalizacaoTexto: json['ultimaLocalizacaoTexto'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        status: json['status'] as String,
        distanciaKm: (json['distanciaKm'] as num?)?.toDouble(),
        tutorNome: (json['tutor'] as Map<String, dynamic>?)?['nome'] as String?,
      );
}
