import 'package:intl/intl.dart';

// Formatação de datas centralizada. Antes cada tela montava a string na mão
// (`padLeft`), o que gerava formatos divergentes entre telas.

final _data = DateFormat('dd/MM/yyyy');
final _dataHora = DateFormat("dd/MM/yyyy 'às' HH:mm");
final _hora = DateFormat('HH:mm');

String formatarData(DateTime data) => _data.format(data);

String formatarDataHora(DateTime data) => _dataHora.format(data);

/// Data/hora em linguagem do dia a dia: "Hoje às 14:30", "Ontem às 09:12"
/// ou a data cheia quando for mais antigo.
String formatarDataHoraRelativa(DateTime data) {
  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(data.year, data.month, data.day);
  final diferencaDias = hoje.difference(dia).inDays;

  if (diferencaDias == 0) return 'Hoje às ${_hora.format(data)}';
  if (diferencaDias == 1) return 'Ontem às ${_hora.format(data)}';
  return _dataHora.format(data);
}

/// Há quanto tempo o animal está desaparecido, para os cards de caso.
String formatarTempoDesaparecido(DateTime dataDesaparecimento) {
  final dias = DateTime.now().difference(dataDesaparecimento).inDays;
  if (dias <= 0) return 'Desaparecido hoje';
  if (dias == 1) return 'Desaparecido há 1 dia';
  return 'Desaparecido há $dias dias';
}

/// Tempo decorrido desde um evento, usado na lista de notificações.
String formatarTempoDecorrido(DateTime data) {
  final diferenca = DateTime.now().difference(data);
  if (diferenca.inMinutes < 1) return 'Agora mesmo';
  if (diferenca.inMinutes == 1) return 'Há 1 minuto';
  if (diferenca.inMinutes < 60) return 'Há ${diferenca.inMinutes} minutos';
  if (diferenca.inHours == 1) return 'Há 1 hora';
  if (diferenca.inHours < 24) return 'Há ${diferenca.inHours} horas';
  if (diferenca.inDays == 1) return 'Há 1 dia';
  return 'Há ${diferenca.inDays} dias';
}

/// "1 avistamento" ou "N avistamentos".
String formatarAvistamentos(int quantidade) => quantidade == 1 ? '1 avistamento' : '$quantidade avistamentos';

/// Distância em km com vírgula, como se escreve no Brasil: "5", "2,5".
String formatarKm(double km) =>
    km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1).replaceAll('.', ',');
