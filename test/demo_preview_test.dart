import 'package:diu_report_box/app/demo_preview.dart';
import 'package:diu_report_box/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo preview renders sample data across the main tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: demoPreviewOverrides,
        child: const DiuReportBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lost student ID card'), findsOneWidget);
    expect(find.textContaining('Demo preview'), findsOneWidget);

    await tester.tap(find.text('Q&A'));
    await tester.pumpAndSettle();
    expect(find.text('How do I register for a retake?'), findsOneWidget);

    await tester.tap(find.text('Maintenance Report'));
    await tester.pumpAndSettle();
    expect(find.text('Select Department'), findsOneWidget);

    await tester.tap(find.text('Resources'));
    await tester.pumpAndSettle();
    expect(find.text('Data Structures Midterm Questions'), findsOneWidget);
  });
}
