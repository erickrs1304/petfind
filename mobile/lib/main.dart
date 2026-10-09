import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/animal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/casos/case_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/root_shell.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.instance.iniciar();
  runApp(const PetFindApp());
}

class PetFindApp extends StatefulWidget {
  const PetFindApp({super.key});

  @override
  State<PetFindApp> createState() => _PetFindAppState();
}

class _PetFindAppState extends State<PetFindApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    PushService.instance.configurar(abrirCaso: _abrirCaso, aoReceberComAppAberto: _mostrarAviso);
  }

  void _abrirCaso(int animalId) {
    _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => CaseDetailScreen(animalId: animalId)));
  }

  // Com o app aberto o sistema não mostra a notificação: atualiza a lista e avisa na tela.
  void _mostrarAviso(String titulo, String corpo, int? animalId) {
    final contexto = _navigatorKey.currentContext;
    if (contexto != null) contexto.read<NotificationProvider>().carregar();
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(corpo.isEmpty ? titulo : '$titulo\n$corpo'),
          duration: const Duration(seconds: 6),
          action: animalId == null ? null : SnackBarAction(label: 'Abrir', onPressed: () => _abrirCaso(animalId)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AnimalProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'PetFind',
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.carregando:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.autenticado:
        return const RootShell();
      case AuthStatus.naoAutenticado:
        return const LoginScreen();
    }
  }
}
