import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'widgets/interactions.dart';
import 'widgets/site_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const PrismApp()));
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppState, ThemeMode>((s) => s.themeMode);
    return MaterialApp.router(
      title: 'PRISM Engine',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: appRouter,
      // Preloader on first load, and the custom cursor layer above every page.
      builder: (context, child) => PreloaderGate(child: CursorFollower(child: child ?? const SizedBox.shrink())),
    );
  }
}
