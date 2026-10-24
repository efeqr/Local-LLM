// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appname/main.dart';

void main() {
  testWidgets('shows the local Ollama chat interface', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Yerel Zeka'), findsOneWidget);
    expect(find.text('Ne düşünüyorsun?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Bağlantı ayarları'), findsOneWidget);
  });
}
