import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
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
  bool _obtendoLocalizacao = false;
  Position? _posicao;
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

  // Ao ligar a opção, pede a permissão e pega a localização na hora. Sem GPS ou sem
  // permissão, avisa e deixa a opção desligada (antes a falha passava em silêncio).
  Future<void> _alterarLocalizacao(bool ligar) async {
    if (!ligar) {
      setState(() {
        _localizacaoAutomatica = false;
        _posicao = null;
      });
      return;
    }
    setState(() => _obtendoLocalizacao = true);
    try {
      final posicao = await obterLocalizacaoAtual();
      if (!mounted) return;
      setState(() {
        _localizacaoAutomatica = true;
        _posicao = posicao;
      });
    } on LocalizacaoException catch (e) {
      if (!mounted) return;
      setState(() => _localizacaoAutomatica = false);
      showAppSnackBar(context, e.message, type: AppSnackType.error);
    } finally {
      if (mounted) setState(() => _obtendoLocalizacao = false);
    }
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

    // A posição já foi obtida quando a opção foi ligada.
    final lat = _localizacaoAutomatica ? _posicao?.latitude : null;
    final lng = _localizacaoAutomatica ? _posicao?.longitude : null;

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
                validator: validarTelefone,
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
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text('Só bairro e cidade. Ex.: Setor Central, Rio Verde',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _localizacaoAutomatica,
                onChanged: _obtendoLocalizacao ? null : _alterarLocalizacao,
                title: const Text('Usar minha localização'),
                subtitle: Text(
                    _obtendoLocalizacao
                        ? 'Obtendo sua localização...'
                        : 'Para receber alertas de animais perdidos perto de você',
                    style: const TextStyle(fontSize: 12)),
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
