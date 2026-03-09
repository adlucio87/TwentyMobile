import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketcrm/main.dart';

void main() {
  testWidgets('PocketCRM app test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: PocketCRMApp()));

    // Verify that our app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
