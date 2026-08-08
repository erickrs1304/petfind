import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/petfind_header.dart';

// RF-003 - Recuperar Senha (Figuras 5 e 6): e-mail e depois código + nova senha na mesma tela.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();

  bool _codigoEnviado = false;
  bool _carregando = false;
  String? _erro;
  String? _mensagem;

  Future<void> _enviarCodigo() async {
    if (_emailController.text.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
      _mensagem = null;
    });
    try {
      final devCode = await context.read<AuthProvider>().forgotPassword(_emailController.text.trim());
      setState(() {
        _codigoEnviado = true;
        _mensagem = devCode != null
            ? 'Código enviado! (Ambiente de teste: código = $devCode)'
            : 'Código enviado para o seu e-mail.';
      });
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'E-mail não encontrado.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _redefinirSenha() async {
    if (_novaSenhaController.text != _confirmarNovaSenhaController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().resetPassword(
            email: _emailController.text.trim(),
            codigo: _codigoController.text.trim(),
            novaSenha: _novaSenhaController.text,
            confirmarNovaSenha: _confirmarNovaSenhaController.text,
          );
      if (!mounted) return;
      showAppSnackBar(context, 'Senha redefinida com sucesso.', type: AppSnackType.success);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Código inválido.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Recuperar senha',
      subtitulo: _codigoEnviado ? 'Informe o código recebido' : 'Vamos te ajudar a voltar',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_erro != null) ...[
              Text(_erro!, style: const TextStyle(color: AppTheme.dangerStrong)),
              const SizedBox(height: 12),
            ],
            if (_mensagem != null) ...[
              Text(_mensagem!, style: const TextStyle(color: AppTheme.successStrong)),
              const SizedBox(height: 12),
            ],
            const SectionLabel('E-mail cadastrado'),
            AppTextField(label: 'E-mail', controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _carregando ? null : _enviarCodigo,
              child: Text(_codigoEnviado ? 'Enviar novo código' : 'Enviar código'),
            ),
            if (_codigoEnviado) ...[
              const SizedBox(height: 24),
              const SectionLabel('Código e nova senha'),
              AppTextField(label: 'Código de verificação', controller: _codigoController, keyboardType: TextInputType.number, maxLength: 6),
              const SizedBox(height: 12),
              AppTextField(label: 'Nova senha', controller: _novaSenhaController, obscureText: true),
              const SizedBox(height: 12),
              AppTextField(label: 'Confirmar nova senha', controller: _confirmarNovaSenhaController, obscureText: true),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _carregando ? null : _redefinirSenha,
                child: const Text('Redefinir senha'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
