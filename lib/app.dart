import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';

class BookMyGroomApp extends ConsumerStatefulWidget {
  const BookMyGroomApp({super.key});

  @override
  ConsumerState<BookMyGroomApp> createState() => _BookMyGroomAppState();
}

class _BookMyGroomAppState extends ConsumerState<BookMyGroomApp> {
  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    push.listen();
    if (ref.read(currentUserProvider) != null) push.register();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Register this device for push whenever someone is signed in.
    ref.listen<AppUser?>(currentUserProvider, (_, user) {
      if (user != null) ref.read(pushServiceProvider).register();
    });

    return MaterialApp.router(
      title: 'BookMyGroom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      scaffoldMessengerKey: rootMessengerKey,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final scale = media.textScaler.clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: media.copyWith(textScaler: scale),
          child: child!,
        );
      },
    );
  }
}
