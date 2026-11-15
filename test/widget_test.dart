import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diu_report_box/core/widgets/empty_state_view.dart';
import 'package:diu_report_box/core/widgets/loading_skeleton.dart';

void main() {
  testWidgets('EmptyStateView renders title and subtitle properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.inbox,
            title: 'No reports found',
            subtitle: 'Try submitting a new report.',
          ),
        ),
      ),
    );

    expect(find.text('No reports found'), findsOneWidget);
    expect(find.text('Try submitting a new report.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
  });

  testWidgets('LoadingSkeletonList renders configured item count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingSkeletonList(itemCount: 3),
        ),
      ),
    );

    expect(find.byType(LoadingSkeletonList), findsOneWidget);
  });
}
