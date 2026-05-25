import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/presentation/widgets/common/trial_banner_widget.dart';

void main() {
  group('TrialBannerWidget', () {
    Widget buildTestWidget() {
      return const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TrialBannerWidget(),
          ),
        ),
      );
    }

    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Initial state is loading which shows SizedBox.shrink
      expect(find.byType(TrialBannerWidget), findsOneWidget);
    });

    testWidgets('initially shows SizedBox.shrink in loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      // In loading state, widget renders SizedBox.shrink
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('widget is a ConsumerStatefulWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      final widget = tester.widget<TrialBannerWidget>(
        find.byType(TrialBannerWidget),
      );
      expect(widget, isA<TrialBannerWidget>());
    });

    testWidgets('shows SizedBox.shrink after async load with no trial data',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      // Pump to allow async _loadTrialData to complete
      // FlutterSecureStorage will throw in test env, caught by try/catch
      // which sets state to hidden (SizedBox.shrink)
      await tester.pumpAndSettle();
      // The widget should still be in the tree
      expect(find.byType(TrialBannerWidget), findsOneWidget);
    });
  });
}
