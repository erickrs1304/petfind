import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Campo de texto com placeholder (sem label flutuante), reproduzindo o
// estilo de inputs cinza-claro do protótipo.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
    this.suffixIcon,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final String? hintText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText ?? (label.isNotEmpty ? label : null),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
