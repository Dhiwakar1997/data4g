import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class DataForgeApp extends StatelessWidget {
  const DataForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DataForge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
