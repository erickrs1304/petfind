class Notificacao {
  Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.referenciaAnimalId,
    required this.lida,
    required this.createdAt,
  });

  final int id;
  final String tipo;
  final String titulo;
  final String mensagem;
  final int? referenciaAnimalId;
  final bool lida;
  final DateTime createdAt;

  factory Notificacao.fromJson(Map<String, dynamic> json) => Notificacao(
        id: json['id'] as int,
        tipo: json['tipo'] as String,
        titulo: json['titulo'] as String,
        mensagem: json['mensagem'] as String,
        referenciaAnimalId: json['referenciaAnimalId'] as int?,
        lida: json['lida'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
