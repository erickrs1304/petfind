import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notificacao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/location_helper.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/petfind_header.dart';
import '../../widgets/state_views.dart';
import '../casos/case_detail_screen.dart';

// RF-008 - Notificações por Proximidade (Figura 11)
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconePorTipo(String tipo) {
    switch (tipo) {
      case 'NOVO_CASO':
        return Icons.pets;
      case 'NOVO_AVISTAMENTO':
        return Icons.location_pin;
      case 'AVISTAMENTO_CONFIRMADO':
        return Icons.notifications_active;
      case 'CASO_ENCERRADO':
        return Icons.celebration_outlined;
      default:
        return Icons.notifications;
    }
  }

  Color _corPorTipo(String tipo) {
    switch (tipo) {
      case 'NOVO_CASO':
        return AppTheme.successStrong;
      case 'NOVO_AVISTAMENTO':
        return AppTheme.primaryStrong;
      case 'AVISTAMENTO_CONFIRMADO':
        return AppTheme.secondaryBadge;
      case 'CASO_ENCERRADO':
        return AppTheme.successStrong;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();

    return PetFindScaffold(
      titulo: 'Notificações',
      subtitulo: 'Alertas da sua região',
      mostrarVoltar: false,
      body: RefreshIndicator(
        onRefresh: () => provider.carregar(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionLabel('Recentes'),
            if (provider.carregando && provider.notificacoes.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: LoadingView())
            else if (provider.notificacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: EmptyView(
                  icon: Icons.notifications_none,
                  title: 'Você ainda não tem notificações',
                  subtitle: 'Alertas de novos casos e avistamentos na sua região aparecerão aqui.',
                ),
              )
            else
              ...provider.notificacoes.map((notificacao) => _cardNotificacao(context, provider, notificacao)),
            const SizedBox(height: 20),
            const SectionLabel('Configurações'),
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                value: auth.usuario?.notificacoesAtivas ?? true,
                onChanged: (v) => _alterarAlertas(context, auth, v),
                title: const Text('Alertas por proximidade'),
                subtitle: const Text('Usa sua localização para avisar sobre animais perdidos perto de você',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: const Text('Raio de alcance'),
                subtitle: Text('Atual: ${formatarKm(auth.usuario?.raioNotificacaoKm ?? 5.0)} km', style: const TextStyle(fontSize: 12)),
                trailing: TextButton(
                  onPressed: () => _editarRaio(context, auth),
                  child: const Text('Editar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardNotificacao(BuildContext context, NotificationProvider provider, Notificacao notificacao) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _corPorTipo(notificacao.tipo), width: 4)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _corPorTipo(notificacao.tipo).withValues(alpha: 0.15),
          child: Icon(_iconePorTipo(notificacao.tipo), color: _corPorTipo(notificacao.tipo)),
        ),
        title: Text(notificacao.titulo, style: TextStyle(fontWeight: notificacao.lida ? FontWeight.normal : FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notificacao.mensagem),
            const SizedBox(height: 2),
            Text(formatarTempoDecorrido(notificacao.createdAt), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        onTap: () async {
          if (!notificacao.lida) await provider.marcarComoLida(notificacao);
          if (notificacao.referenciaAnimalId != null && context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CaseDetailScreen(animalId: notificacao.referenciaAnimalId!)),
            );
          }
        },
      ),
    );
  }

  // Os alertas por proximidade dependem da localização: ligá-los autoriza o uso da posição
  // do aparelho; desligá-los apaga a localização salva no perfil.
  Future<void> _alterarAlertas(BuildContext context, AuthProvider auth, bool ligar) async {
    try {
      if (!ligar) {
        await auth.atualizarPerfil({'notificacoesAtivas': false, 'lat': null, 'lng': null});
        return;
      }
      final posicao = await obterLocalizacaoAtual();
      await auth.atualizarPerfil({'notificacoesAtivas': true, 'lat': posicao.latitude, 'lng': posicao.longitude});
    } on LocalizacaoException catch (e) {
      if (context.mounted) showAppSnackBar(context, e.message, type: AppSnackType.error);
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, extractErrorMessage(e), type: AppSnackType.error);
    }
  }

  Future<void> _editarRaio(BuildContext context, AuthProvider auth) async {
    final controller = TextEditingController(text: formatarKm(auth.usuario?.raioNotificacaoKm ?? 5.0));
    final novoRaio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raio de alcance'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'km'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (novoRaio == null) return;
    // Aceita vírgula ("2,5"), como se digita no Brasil; valor inválido avisa em vez de sumir.
    final valor = double.tryParse(novoRaio.trim().replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      if (context.mounted) showAppSnackBar(context, 'Informe um raio maior que zero, em km.', type: AppSnackType.error);
      return;
    }
    try {
      await auth.atualizarPerfil({'raioNotificacaoKm': valor});
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, extractErrorMessage(e), type: AppSnackType.error);
    }
  }
}
