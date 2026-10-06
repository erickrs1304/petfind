import 'package:flutter_test/flutter_test.dart';
import 'package:petfind/utils/formatters.dart';

// Teste unitário puro (sem widget/UI): exercita as funções de formatação
// diretamente, injetando DateTimes fixos.
void main() {
  group('formatarData', () {
    test('formata no padrão dd/MM/yyyy', () {
      expect(formatarData(DateTime(2026, 1, 5)), '05/01/2026');
    });
  });

  group('formatarDataHora', () {
    test('formata no padrão dd/MM/yyyy às HH:mm', () {
      expect(formatarDataHora(DateTime(2026, 3, 20, 14, 30)), "20/03/2026 às 14:30");
    });
  });

  group('formatarDataHoraRelativa', () {
    test('retorna "Hoje às HH:mm" para um horário no dia atual', () {
      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day, 9, 15);
      expect(formatarDataHoraRelativa(hoje), startsWith('Hoje às'));
    });

    test('retorna "Ontem às HH:mm" para um horário no dia anterior', () {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      final dataOntem = DateTime(ontem.year, ontem.month, ontem.day, 9, 15);
      expect(formatarDataHoraRelativa(dataOntem), startsWith('Ontem às'));
    });

    test('retorna a data cheia para um horário de mais de 1 dia atrás', () {
      final data = DateTime.now().subtract(const Duration(days: 10));
      final dataAntiga = DateTime(data.year, data.month, data.day, 9, 15);
      expect(formatarDataHoraRelativa(dataAntiga), formatarDataHora(dataAntiga));
    });
  });

  group('formatarTempoDesaparecido', () {
    test('retorna "Desaparecido hoje" para uma data de hoje', () {
      expect(formatarTempoDesaparecido(DateTime.now()), 'Desaparecido hoje');
    });

    test('retorna singular para 1 dia', () {
      final ontem = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatarTempoDesaparecido(ontem), 'Desaparecido há 1 dia');
    });

    test('retorna plural para vários dias', () {
      final dias5 = DateTime.now().subtract(const Duration(days: 5, hours: 1));
      expect(formatarTempoDesaparecido(dias5), 'Desaparecido há 5 dias');
    });
  });

  group('formatarTempoDecorrido', () {
    test('retorna "Agora mesmo" para menos de 1 minuto', () {
      final agora = DateTime.now().subtract(const Duration(seconds: 10));
      expect(formatarTempoDecorrido(agora), 'Agora mesmo');
    });

    test('retorna minutos para menos de 1 hora', () {
      final minutosAtras = DateTime.now().subtract(const Duration(minutes: 20));
      expect(formatarTempoDecorrido(minutosAtras), 'Há 20 minutos');
    });

    test('retorna horas para menos de 1 dia', () {
      final horasAtras = DateTime.now().subtract(const Duration(hours: 3));
      expect(formatarTempoDecorrido(horasAtras), 'Há 3 horas');
    });

    test('retorna singular para 1 dia', () {
      final diaAtras = DateTime.now().subtract(const Duration(days: 1, hours: 1));
      expect(formatarTempoDecorrido(diaAtras), 'Há 1 dia');
    });

    test('retorna plural para vários dias', () {
      final diasAtras = DateTime.now().subtract(const Duration(days: 4, hours: 1));
      expect(formatarTempoDecorrido(diasAtras), 'Há 4 dias');
    });
  });
}
