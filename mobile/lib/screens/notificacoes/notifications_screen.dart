import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/notificacao.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/petfind_header.dart';
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
      default:
        return Icons.notifications;
    }
  }

  Color _corPorTipo(String tipo) {
    switch (tipo) {
      case 'NOVO_CASO':
        return AppTheme.success;
      case 'NOVO_AVISTAMENTO':
        return AppTheme.primary;
      case 'AVISTAMENTO_CONFIRMADO':
        return AppTheme.secondaryBadge;
      default:
        return Colors.grey;
    }
  }

  String _tempoRelativo(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'Há ${diff.inHours} horas';
    return 'Há ${diff.inDays} dias';
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
              const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
            else if (provider.notificacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Você ainda não tem notificações.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...provider.notificacoes.map((notificacao) => _cardNotificacao(context, provider, notificacao)),
            const SizedBox(height: 20),
            const SectionLabel('Configurações'),
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
              child: SwitchListTile(
                value: auth.usuario?.notificacoesAtivas ?? true,
                onChanged: (v) => auth.atualizarPerfil({'notificacoesAtivas': v}),
                title: const Text('Alertas por proximidade'),
                subtitle: const Text('Receber notificações da região', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: const Text('Raio de alcance'),
                subtitle: Text('Atual: ${auth.usuario?.raioNotificacaoKm.toStringAsFixed(0) ?? 5} km', style: const TextStyle(fontSize: 12)),
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
            Text(_tempoRelativo(notificacao.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
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

  Future<void> _editarRaio(BuildContext context, AuthProvider auth) async {
    final controller = TextEditingController(text: auth.usuario?.raioNotificacaoKm.toStringAsFixed(0) ?? '5');
    final novoRaio = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raio de alcance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'km'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (novoRaio == null) return;
    final valor = double.tryParse(novoRaio);
    if (valor == null || valor <= 0) return;
    await auth.atualizarPerfil({'raioNotificacaoKm': valor});
  }
}
