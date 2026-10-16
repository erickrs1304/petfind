import '../../utils/constants.dart';

class Avistamento {
  Avistamento({
    required this.id,
    required this.animalId,
    required this.usuarioId,
    required this.lat,
    required this.lng,
    required this.dataHora,
    this.comentario,
    this.comentarioTutor,
    this.fotoUrl,
    required this.status,
    this.colaboradorNome,
  });

  final int id;
  final int animalId;
  final int usuarioId;
  final double lat;
  final double lng;
  final DateTime dataHora;
  final String? comentario;
  final String? comentarioTutor;
  final String? fotoUrl;
  final String status;
  final String? colaboradorNome;

  // Fotos novas ficam no Supabase Storage (URL absoluta); as antigas são relativas à API.
  String? get fotoUrlCompleta => fotoUrl == null ? null : (fotoUrl!.startsWith('http') ? fotoUrl : '$kApiBaseUrl$fotoUrl');

  factory Avistamento.fromJson(Map<String, dynamic> json) => Avistamento(
        id: json['id'] as int,
        animalId: json['animalId'] as int,
        usuarioId: json['usuarioId'] as int,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        dataHora: DateTime.parse(json['dataHora'] as String),
        comentario: json['comentario'] as String?,
        comentarioTutor: json['comentarioTutor'] as String?,
        fotoUrl: json['fotoUrl'] as String?,
        status: json['status'] as String,
        colaboradorNome: (json['colaborador'] as Map<String, dynamic>?)?['nome'] as String?,
      );
}
