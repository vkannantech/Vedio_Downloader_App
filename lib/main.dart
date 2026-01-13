import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/di/logic_provider.dart';
import 'core/di/database_provider.dart';
import 'core/di/app_init_provider.dart';
import 'ui/main_screen.dart';

void main() {
  runApp(const ProviderScope(child: ClivonApp()));
}

class ClivonApp extends ConsumerWidget {
  const ClivonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initAsync = ref.watch(appInitProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clivon',
      theme: AppTheme.darkTheme,
      home: initAsync.when(
        data: (isar) {
          return const MainScreen();
        },
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF1E1E2C), // Match app theme
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        ),
      ),
    );
  }
}
