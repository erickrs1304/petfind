import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/politica_privacidade.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/petfind_header.dart';

// RF-001 - Manter Usuário: fluxo de cadastro (Figura 2)
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _regiaoController = TextEditingController();
  // Desligado por padrão: a pessoa decide se a localização pode ser usada nos alertas (LGPD).
  bool _localizacaoAutomatica = false;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _regiaoController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_senhaController.text != _confirmarSenhaController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final authProvider = context.read<AuthProvider>();

    double? lat;
    double? lng;
    if (_localizacaoAutomatica) {
      try {
        final posicao = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = posicao.latitude;
        lng = posicao.longitude;
      } catch (_) {
        // Localização é opcional no cadastro; a região textual já é suficiente.
      }
    }

    try {
      await authProvider.register(
            nome: _nomeController.text.trim(),
            email: _emailController.text.trim(),
            telefone: _telefoneController.text.trim(),
            usarLocalizacao: _localizacaoAutomatica,
            senha: _senhaController.text,
            confirmarSenha: _confirmarSenhaController.text,
            regiao: _regiaoController.text.trim(),
            lat: lat,
            lng: lng,
          );
      if (!mounted) return;
      showAppSnackBar(context, 'Cadastro realizado com sucesso!', type: AppSnackType.success);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível concluir o cadastro.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PetFindScaffold(
      titulo: 'Criar conta',
      subtitulo: 'Junte-se à comunidade',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUnfocus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: AppTheme.dangerStrong)),
                const SizedBox(height: 12),
              ],
              const SectionLabel('Dados pessoais'),
              AppTextField(
                label: 'Nome',
                controller: _nomeController,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'E-mail',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Preencha todos os campos obrigatórios.';
                  if (!v.contains('@')) return 'Informe um e-mail válido.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Telefone',
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                hintText: '(99) 99999-9999',
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Senha',
                controller: _senhaController,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Preencha todos os campos obrigatórios.';
                  if (v.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Confirmar senha',
                controller: _confirmarSenhaController,
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Localização'),
              AppTextField(
                label: 'Cidade/Bairro',
                controller: _regiaoController,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _localizacaoAutomatica,
                onChanged: (v) => setState(() => _localizacaoAutomatica = v),
                title: const Text('Usar minha localização'),
                subtitle: const Text('Para receber alertas de animais perdidos perto de você',
                    style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregando ? null : _cadastrar,
                child: _carregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Continuar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => abrirPoliticaPrivacidade(context),
                child: const Text('Política de privacidade'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
