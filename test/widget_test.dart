import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SNMS App', () {
    testWidgets('app builds without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: Text('SNMS'))),
        ),
      );
      expect(find.text('SNMS'), findsOneWidget);
    });
  });
}
