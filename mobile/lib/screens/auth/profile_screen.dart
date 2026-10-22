import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_client.dart';
import '../../data/models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/politica_privacidade.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/petfind_header.dart';
import '../casos/my_cases_screen.dart';

// RF-001 - Manter Usuário: edição de perfil (Figura 3)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Telefones salvos antes da máscara aparecem só com dígitos; formata para exibir.
  static String _mascarar(String? telefone, {String vazio = ''}) {
    final digitos = (telefone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digitos.isEmpty) return vazio;
    return formatarTelefone(digitos.length > 11 ? digitos.substring(0, 11) : digitos);
  }

  final _formKey = GlobalKey<FormState>();
  bool _editando = false;
  bool _carregando = false;
  String? _erro;

  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _regiaoController;
  final _novaSenhaController = TextEditingController();
  final _senhaExclusaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().usuario!;
    _nomeController = TextEditingController(text: usuario.nome);
    _telefoneController = TextEditingController(text: _mascarar(usuario.telefone));
    _regiaoController = TextEditingController(text: usuario.regiao);
  }

  // O "X" descarta o que foi digitado: ao editar de novo, os campos voltam aos dados salvos.
  void _cancelarEdicao() {
    final usuario = context.read<AuthProvider>().usuario!;
    _nomeController.text = usuario.nome;
    _telefoneController.text = _mascarar(usuario.telefone);
    _regiaoController.text = usuario.regiao;
    _novaSenhaController.clear();
    setState(() {
      _editando = false;
      _erro = null;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().atualizarPerfil({
        'nome': _nomeController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'regiao': _regiaoController.text.trim(),
        if (_novaSenhaController.text.isNotEmpty) 'senha': _novaSenhaController.text,
      });
      if (!mounted) return;
      _novaSenhaController.clear();
      setState(() => _editando = false);
      showAppSnackBar(context, 'Perfil atualizado com sucesso.', type: AppSnackType.success);
    } catch (e) {
      setState(() => _erro = extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // RF-001 - exclusão da conta: pede a senha porque apaga tudo e não tem volta.
  Future<void> _excluirConta() async {
    _senhaExclusaoController.clear();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seus dados, os casos que você cadastrou, os avistamentos que registrou e as fotos '
                'serão apagados. Essa ação não pode ser desfeita.'),
            const SizedBox(height: 16),
            AppTextField(label: 'Confirme sua senha', controller: _senhaExclusaoController, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerStrong),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await context.read<AuthProvider>().excluirConta(_senhaExclusaoController.text);
      if (!mounted) return;
      showAppSnackBar(context, 'Conta excluída.', type: AppSnackType.success);
    } catch (e) {
      if (mounted) setState(() => _erro = extractErrorMessage(e, fallback: 'Não foi possível excluir a conta.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _senhaExclusaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuario!;

    return PetFindScaffold(
      titulo: 'Meu perfil',
      mostrarVoltar: false,
      acoes: [
        IconButton(
          icon: Icon(_editando ? Icons.close : Icons.edit, color: Colors.white),
          onPressed: _editando ? _cancelarEdicao : () => setState(() => _editando = true),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const CircleAvatar(radius: 40, backgroundColor: Color(0x1FFF7A45), child: Icon(Icons.person, size: 40, color: AppTheme.primaryStrong)),
              const SizedBox(height: 24),
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: AppTheme.dangerStrong)),
                const SizedBox(height: 12),
              ],
              if (_editando) ..._camposEdicao() else ..._camposLeitura(usuario),
              if (!_editando) ...[
                const SizedBox(height: 16),
                const SectionLabel('Meus casos'),
                Container(
                  decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: const Icon(Icons.folder_shared_outlined, color: AppTheme.primaryStrong),
                    title: const Text('Casos que cadastrei'),
                    subtitle: const Text('Editar casos ativos e ver os encerrados', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyCasesScreen()),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_editando)
                ElevatedButton(
                  onPressed: _carregando ? null : _salvar,
                  child: _carregando
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Salvar'),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Sair'),
              ),
              if (!_editando) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => abrirPoliticaPrivacidade(context),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Política de privacidade'),
                ),
                TextButton.icon(
                  onPressed: _carregando ? null : _excluirConta,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.dangerStrong),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir conta'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _camposLeitura(Usuario usuario) => [
        _cardInfo(Icons.badge_outlined, 'Nome', usuario.nome),
        _cardInfo(Icons.email_outlined, 'E-mail', usuario.email),
        _cardInfo(Icons.phone_outlined, 'Telefone', _mascarar(usuario.telefone, vazio: '-')),
        _cardInfo(Icons.place_outlined, 'Região', usuario.regiao),
      ];

  Widget _cardInfo(IconData icone, String rotulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icone, color: AppTheme.primaryStrong),
        title: Text(rotulo, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        subtitle: Text(valor),
      ),
    );
  }

  // Mesmas mensagens do cadastro; sem elas a API só respondia "Dados inválidos.".
  static String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Preencha todos os campos obrigatórios.' : null;

  List<Widget> _camposEdicao() => [
        const SectionLabel('Dados pessoais'),
        AppTextField(label: 'Nome', controller: _nomeController, validator: _obrigatorio),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Telefone',
          controller: _telefoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          validator: validarTelefone,
        ),
        const SizedBox(height: 12),
        AppTextField(label: 'Região (bairro/cidade)', controller: _regiaoController, validator: _obrigatorio),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Nova senha (opcional)',
          controller: _novaSenhaController,
          obscureText: true,
          validator: (v) => (v != null && v.isNotEmpty && v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres.' : null,
        ),
      ];
}
