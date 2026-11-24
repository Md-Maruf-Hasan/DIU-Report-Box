import 'package:diu_report_box/app/demo_preview.dart';
import 'package:diu_report_box/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login form fits a phone-width screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: demoPreviewOverrides,
        child: const DiuReportBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo preview starts at login and opens sample data after submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: demoPreviewOverrides,
        child: const DiuReportBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'student@diu.edu.bd');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Lost student ID card'), findsOneWidget);

    await tester.tap(find.text('Q&A'));
    await tester.pumpAndSettle();
    expect(find.text('How do I register for a retake?'), findsOneWidget);
  });
}
