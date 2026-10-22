import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/petfind_header.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

// RF-002 - Realizar Login (Figura 4)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// RF-002 A2: após 3 tentativas erradas o servidor bloqueia o login por 5 minutos
// (HTTP 429); o botão "Entrar" fica desabilitado até o prazo acabar.
const _duracaoBloqueio = Duration(minutes: 5);

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;
  DateTime? _bloqueadoAte;
  Timer? _relogio;

  bool get _bloqueado => _bloqueadoAte != null && DateTime.now().isBefore(_bloqueadoAte!);

  String get _tempoRestante {
    final restante = _bloqueadoAte!.difference(DateTime.now());
    final segundos = (restante.inSeconds % 60).toString().padLeft(2, '0');
    return '${restante.inMinutes}:$segundos';
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _iniciarBloqueio() {
    _bloqueadoAte = DateTime.now().add(_duracaoBloqueio);
    _relogio?.cancel();
    _relogio = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_bloqueado) {
        setState(() {});
      } else {
        timer.cancel();
        setState(() {
          _bloqueadoAte = null;
          _erro = null;
        });
      }
    });
  }

  // Com a senha redefinida, o servidor libera o login; o contador do bloqueio sai junto.
  Future<void> _abrirRecuperacao() async {
    final redefiniu = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
    if (redefiniu == true && mounted) {
      _relogio?.cancel();
      setState(() {
        _bloqueadoAte = null;
        _erro = null;
      });
    }
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().login(email: _emailController.text.trim(), senha: _senhaController.text);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) _iniciarBloqueio();
      setState(() => _erro = extractErrorMessage(e, fallback: 'E-mail ou senha inválidos.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Bem-vindo',
      mostrarVoltar: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUnfocus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 32, color: AppTheme.primaryStrong),
                  const SizedBox(width: 8),
                  Text('PetFind', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryStrong, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Plataforma colaborativa para busca de pets', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 32),
              const SectionLabel('Suas credenciais'),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: AppTheme.dangerStrong)),
                const SizedBox(height: 12),
              ],
              AppTextField(
                label: '',
                hintText: 'E-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe seu e-mail.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: '',
                hintText: 'Senha',
                controller: _senhaController,
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Informe sua senha.' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_carregando || _bloqueado) ? null : _entrar,
                child: _carregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_bloqueado ? 'Tente novamente em $_tempoRestante' : 'Entrar'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _abrirRecuperacao,
                child: const Text('Esqueci minha senha'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('ou', style: Theme.of(context).textTheme.bodySmall)),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text('Criar nova conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
