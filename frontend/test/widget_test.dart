import 'package:dataforge_frontend/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('landing page renders brand shell', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1200));
    await tester.pumpWidget(
      const ProviderScope(
        child: DataForgeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DataForge'), findsWidgets);
    expect(find.textContaining('topology'), findsWidgets);

    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
