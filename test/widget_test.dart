import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:karachords/app.dart';
import 'package:karachords/data/local/drift_database.dart';
import 'package:karachords/presentation/providers/providers.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const KaraChordsApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    addTearDown(testDb.close);
  });
}
