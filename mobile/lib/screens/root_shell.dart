import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import 'auth/profile_screen.dart';
import 'casos/home_screen.dart';
import 'notificacoes/notifications_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _indiceAtual = 0;

  final _telas = const [HomeScreen(), NotificationsScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().carregar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Push recebido com o app em segundo plano não passa pelo onMessage: a lista e o
  // contador de Notificações são atualizados quando o app volta para a frente.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<NotificationProvider>().carregar();
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = context.watch<NotificationProvider>().naoLidas;

    return Scaffold(
      body: IndexedStack(index: _indiceAtual, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (i) {
          setState(() => _indiceAtual = i);
          if (i == 1) context.read<NotificationProvider>().carregar();
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Casos'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: naoLidas > 0,
              label: Text('$naoLidas'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notificações',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
