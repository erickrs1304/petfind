import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api_client.dart';
import '../../data/models/animal.dart';
import '../../data/models/picked_photo.dart';
import '../../data/repositories/animal_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/location_helper.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/dashed_photo_picker.dart';
import '../../widgets/location_capture_card.dart';
import '../../widgets/petfind_header.dart';

// RF-004 - Manter Animal Perdido: cadastro (Figura 7) e edição (fluxo 3.2).
// A mesma tela atende os dois fluxos; passar [animalParaEditar] ativa o modo de edição.
class CreateCaseScreen extends StatefulWidget {
  const CreateCaseScreen({super.key, this.animalParaEditar});

  final Animal? animalParaEditar;

  @override
  State<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends State<CreateCaseScreen> {
  static const _portes = ['Pequeno', 'Médio', 'Grande'];

  final _formKey = GlobalKey<FormState>();
  final _repository = AnimalRepository();

  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _caracteristicasController = TextEditingController();
  final _localizacaoController = TextEditingController();

  String _especie = 'Cachorro';
  String? _porte;
  DateTime? _dataDesaparecimento;
  PickedPhoto? _foto;

  // Coordenada do desaparecimento que será enviada. No cadastro vem do GPS; na
  // edição começa com a que já está salva e só muda se o tutor pedir.
  double? _lat;
  double? _lng;

  bool _obtendoLocalizacao = false;
  bool _carregando = false;
  String? _erro;
  String? _erroLocalizacao;

  bool get _editando => widget.animalParaEditar != null;

  @override
  void initState() {
    super.initState();
    final animal = widget.animalParaEditar;
    if (animal != null) {
      _nomeController.text = animal.nome;
      _racaController.text = animal.raca ?? '';
      _caracteristicasController.text = animal.caracteristicas;
      _localizacaoController.text = animal.ultimaLocalizacaoTexto;
      _especie = animal.especie;
      _porte = _portes.contains(animal.porte) ? animal.porte : null;
      _dataDesaparecimento = animal.dataDesaparecimento;
      _lat = animal.lat;
      _lng = animal.lng;
    } else {
      _obterLocalizacao();
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _caracteristicasController.dispose();
    _localizacaoController.dispose();
    super.dispose();
  }

  Future<void> _obterLocalizacao() async {
    setState(() {
      _obtendoLocalizacao = true;
      _erroLocalizacao = null;
    });
    try {
      final posicao = await obterLocalizacaoAtual();
      setState(() {
        _lat = posicao.latitude;
        _lng = posicao.longitude;
      });
    } on LocalizacaoException catch (e) {
      setState(() => _erroLocalizacao = e.message);
    } finally {
      if (mounted) setState(() => _obtendoLocalizacao = false);
    }
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataDesaparecimento ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (data != null) setState(() => _dataDesaparecimento = data);
  }

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (imagem == null) return;
    final bytes = await imagem.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _erro = 'A imagem deve ter no máximo 5MB.');
      return;
    }
    setState(() {
      _foto = PickedPhoto(bytes: bytes, filename: imagem.name);
      _erro = null;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataDesaparecimento == null) {
      setState(() => _erro = 'Informe a data do desaparecimento.');
      return;
    }
    if (_localizacaoController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe a última localização do animal.');
      return;
    }
    if (_lat == null || _lng == null) {
      setState(() => _erro = 'Não foi possível obter sua localização. Ative o GPS e tente novamente.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final raca = _racaController.text.trim();
      if (_editando) {
        await _repository.editar(
          id: widget.animalParaEditar!.id,
          nome: _nomeController.text.trim(),
          especie: _especie,
          raca: raca,
          porte: _porte,
          caracteristicas: _caracteristicasController.text.trim(),
          dataDesaparecimento: _dataDesaparecimento!,
          ultimaLocalizacaoTexto: _localizacaoController.text.trim(),
          lat: _lat!,
          lng: _lng!,
          foto: _foto,
        );
      } else {
        await _repository.criar(
          nome: _nomeController.text.trim(),
          especie: _especie,
          raca: raca,
          porte: _porte,
          caracteristicas: _caracteristicasController.text.trim(),
          dataDesaparecimento: _dataDesaparecimento!,
          ultimaLocalizacaoTexto: _localizacaoController.text.trim(),
          lat: _lat!,
          lng: _lng!,
          foto: _foto,
        );
      }

      if (!mounted) return;
      showAppSnackBar(
        context,
        _editando ? 'Caso atualizado com sucesso!' : 'Caso cadastrado com sucesso!',
        type: AppSnackType.success,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _erro = extractErrorMessage(
            e,
            fallback: _editando ? 'Não foi possível salvar as alterações.' : 'Não foi possível registrar o caso.',
          ));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Widget _chipEspecie(String valor, IconData icone) {
    final selecionado = _especie == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _especie = valor),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selecionado ? AppTheme.primaryStrong.withValues(alpha: 0.12) : AppTheme.surfaceCard,
            border: Border.all(color: selecionado ? AppTheme.primaryStrong : Colors.transparent, width: 1.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(icone, color: selecionado ? AppTheme.primaryStrong : Colors.grey),
              const SizedBox(height: 2),
              Text(valor, style: TextStyle(color: selecionado ? AppTheme.primaryStrong : Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fotoAtual = widget.animalParaEditar?.fotoUrlCompleta;

    return PetFindScaffold(
      titulo: _editando ? 'Editar Caso' : 'Animal Perdido',
      subtitulo: _editando ? 'Atualize as informações do caso' : 'Preencha as informações',
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
              const SectionLabel('Sobre o animal'),
              DashedPhotoPicker(
                onTap: _selecionarFoto,
                fotoBytes: _foto?.bytes,
                fotoUrl: _foto == null ? fotoAtual : null,
                texto: _editando ? 'Trocar foto do animal' : 'Adicionar foto do animal',
                height: 130,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nome do animal',
                controller: _nomeController,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 16),
              const Text('Espécie', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(children: [
                _chipEspecie('Cachorro', Icons.pets),
                _chipEspecie('Gato', Icons.cruelty_free),
                _chipEspecie('Outro', Icons.emoji_nature),
              ]),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: AppTextField(label: 'Raça (opcional)', controller: _racaController)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // Campo de seleção conforme o Quadro 14 do DERS — o back-end
                      // só aceita estes três valores.
                      initialValue: _porte,
                      decoration: const InputDecoration(labelText: 'Porte (opcional)'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('Não informado')),
                        ..._portes.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (valor) => setState(() => _porte = valor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Pelagem, coleira, marcas...',
                controller: _caracteristicasController,
                maxLines: 3,
                maxLength: 200,
                validator: (v) => (v == null || v.isEmpty) ? 'Preencha todos os campos obrigatórios.' : null,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Desaparecimento'),
              InkWell(
                onTap: _selecionarData,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                    _dataDesaparecimento == null ? 'dd/mm/aaaa' : formatarData(_dataDesaparecimento!),
                    style: TextStyle(color: _dataDesaparecimento == null ? AppTheme.textMuted : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Rua, bairro, referência...',
                controller: _localizacaoController,
                suffixIcon: const Icon(Icons.location_on_outlined),
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a última localização do animal.' : null,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 12),
                child: Text(
                  'Referência legível — a coordenada GPS exata é capturada abaixo.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ),
              LocationCaptureCard(
                obtendo: _obtendoLocalizacao,
                lat: _lat,
                lng: _lng,
                erro: _erroLocalizacao,
                onRetry: _obterLocalizacao,
                mostrarHorario: !_editando,
                tituloOk: _editando
                    ? 'Ponto do desaparecimento registrado neste caso'
                    : 'GPS capturado — este é o ponto do desaparecimento',
                // Na edição a coordenada salva é preservada por padrão: recapturar o
                // GPS aqui moveria o ponto do desaparecimento para onde o tutor está agora.
                acaoExtra: _editando
                    ? TextButton.icon(
                        onPressed: _obtendoLocalizacao ? null : _obterLocalizacao,
                        icon: const Icon(Icons.my_location, size: 18),
                        label: const Text('Atualizar com meu GPS atual'),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: (_carregando || _lat == null) ? null : _salvar,
                icon: _carregando ? null : Icon(_editando ? Icons.save_outlined : Icons.campaign_outlined),
                label: _carregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_editando ? 'Salvar alterações' : 'Publicar Alerta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
