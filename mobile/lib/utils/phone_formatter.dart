import 'package:flutter/services.dart';

// Máscara (99) 99999-9999 do campo Telefone (RF-001). Aceita 10 ou 11 dígitos.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 11 ? digitos.substring(0, 11) : digitos;
    final texto = formatarTelefone(limitado);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

String formatarTelefone(String digitos) {
  if (digitos.isEmpty) return '';
  final b = StringBuffer('(');
  b.write(digitos.substring(0, digitos.length < 2 ? digitos.length : 2));
  if (digitos.length < 3) return b.toString();
  b.write(') ');
  final corte = digitos.length > 10 ? 7 : 6;
  b.write(digitos.substring(2, digitos.length < corte ? digitos.length : corte));
  if (digitos.length > corte) {
    b.write('-');
    b.write(digitos.substring(corte));
  }
  return b.toString();
}
