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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().login(email: _emailController.text.trim(), senha: _senhaController.text);
    } catch (e) {
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
                onPressed: _carregando ? null : _entrar,
                child: _carregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
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
