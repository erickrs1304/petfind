import 'package:flutter/material.dart';

// RNF-001: interface moderna, intuitiva, cores suaves, ícones padronizados.
// Paleta segue o protótipo do TCC (laranja, cabeçalho em gradiente, botões
// em pílula), mas com tons "Strong" dedicados a texto/ícone/preenchimento de
// botão — as cores originais (primary/success/danger) só devem ser usadas de
// forma decorativa (fundos com alpha baixo, gradientes, estados não
// selecionados), pois não atingem o contraste mínimo de 4.5:1 do WCAG AA
// contra o fundo do app quando usadas como texto.
class AppTheme {
  static const Color primary = Color(0xFFFF7A45);
  static const Color primaryDark = Color(0xFFF4652A);
  static const Color background = Color(0xFFEDEAE6);
  static const Color surfaceCard = Color(0xFFF2F0ED);
  static const Color success = Color(0xFF3FAE5C);
  static const Color danger = Color(0xFFE8543E);
  static const Color secondaryBadge = Color(0xFF3F72AF);

  // Variantes de contraste AA (texto, ícone informativo, fundo de botão com
  // texto branco em cima). Todas com folga acima de 4.5:1 contra #EDEAE6.
  static const Color primaryStrong = Color(0xFFA83D0D);
  static const Color successStrong = Color(0xFF1B6E3C);
  static const Color dangerStrong = Color(0xFFBD3720);
  static const Color textMuted = Color(0xFF616161);

  static const List<Color> headerGradient = [Color(0xFFFF8A5B), Color(0xFFF4652A)];
  static const List<Color> primaryButtonGradient = [Color(0xFFFF9466), Color(0xFFF4652A)];
  static const List<Color> successGradient = [Color(0xFF4CC26E), Color(0xFF34A853)];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(
      // copyWith sobre o estilo base (e não um TextStyle novo) preserva a cor do
      // tema; sem isso o texto sem cor explícita sai branco sobre fundo claro.
      textTheme: base.textTheme.copyWith(
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12, color: textMuted),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: primaryStrong,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryStrong,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryStrong,
          side: const BorderSide(color: primaryStrong, width: 1.4),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryStrong),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryStrong, width: 1.4),
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryStrong : Colors.grey.shade300,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryStrong.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? primaryStrong : Colors.grey),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primaryStrong : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Ritmo de espaçamento usado pelos componentes reutilizáveis do app.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// Estilo de rótulo de seção usado nos formulários do protótipo
// (ex.: "DADOS PESSOAIS", "LOCALIZAÇÃO"): caixa alta, laranja, negrito.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(texto.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
