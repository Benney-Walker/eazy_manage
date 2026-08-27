import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/logging/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.instance.init();

  // Route uncaught framework + platform errors into the activity log.
  final priorOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLog.e('error', details.exceptionAsString(), details.stack?.toString());
    priorOnError?.call(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLog.e('error', error.toString(), stack.toString());
    return false;
  };

  AppLog.i('app', 'App started');
  runApp(const ProviderScope(child: EazyManageApp()));
}

class EazyManageApp extends ConsumerWidget {
  const EazyManageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EazyManage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}