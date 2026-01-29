// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EngineOilShopApp());

    // Verify that our app shows splash screen initially.
    expect(find.text('Engine Oil Shop'), findsOneWidget);
    expect(find.text('Management System'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Wait for the timer to complete and pump frames
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // After splash screen, we should see login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
