class Usuario {
  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    required this.regiao,
    this.lat,
    this.lng,
    required this.raioNotificacaoKm,
    this.notificacoesAtivas = true,
  });

  final int id;
  final String nome;
  final String email;
  final String? telefone;
  final String regiao;
  final double? lat;
  final double? lng;
  final double raioNotificacaoKm;
  final bool notificacoesAtivas;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String,
        telefone: json['telefone'] as String?,
        regiao: json['regiao'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        raioNotificacaoKm: (json['raioNotificacaoKm'] as num?)?.toDouble() ?? 5,
        notificacoesAtivas: json['notificacoesAtivas'] as bool? ?? true,
      );
}
