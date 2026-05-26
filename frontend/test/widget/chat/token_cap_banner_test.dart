import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/presentation/widgets/chat/token_cap_banner.dart';

void main() {
  group('TokenCapBanner', () {
    bool addKeyCalled = false;

    setUp(() {
      addKeyCalled = false;
    });

    Widget buildTestWidget({
      required int used,
      required int limit,
      String capType = 'five_hour',
      String resetsIn = '2h 30m',
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TokenCapBanner(
            capType: capType,
            used: used,
            limit: limit,
            resetsIn: resetsIn,
            onAddKey: () => addKeyCalled = true,
          ),
        ),
      );
    }

    testWidgets('shows SizedBox.shrink when percentage < 0.7',
        (WidgetTester tester) async {
      // 50% usage (5000 / 10000 = 0.5)
      await tester.pumpWidget(buildTestWidget(used: 5000, limit: 10000));

      // Should render SizedBox.shrink
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('shows warning state when percentage between 0.7 and 1.0',
        (WidgetTester tester) async {
      // 80% usage (8000 / 10000 = 0.8)
      await tester.pumpWidget(buildTestWidget(used: 8000, limit: 10000));

      // Should show warning icon
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      // Should show Add key button
      expect(find.text('Add key'), findsOneWidget);
      // Should show percentage
      expect(find.textContaining('80%'), findsOneWidget);
    });

    testWidgets('shows blocked state when percentage >= 1.0',
        (WidgetTester tester) async {
      // 100% usage (10000 / 10000 = 1.0)
      await tester.pumpWidget(buildTestWidget(used: 10000, limit: 10000));

      // Should show block icon
      expect(find.byIcon(Icons.block), findsOneWidget);
      // Should show Add key button
      expect(find.text('Add key'), findsOneWidget);
    });

    testWidgets('blocked state shows token blocked message',
        (WidgetTester tester) async {
      // Over 100% usage
      await tester.pumpWidget(buildTestWidget(used: 12000, limit: 10000));

      // Should show the blocked message from FunnyWarnings
      expect(
        find.text('You hit the wall. Even Mio needs a break.'),
        findsOneWidget,
      );
      expect(
        find.text('Add your own API key to continue'),
        findsOneWidget,
      );
    });

    testWidgets('onAddKey callback is triggered when Add key is pressed',
        (WidgetTester tester) async {
      // Blocked state
      await tester.pumpWidget(buildTestWidget(used: 10000, limit: 10000));

      await tester.tap(find.text('Add key'));
      await tester.pumpAndSettle();

      expect(addKeyCalled, true);
    });

    testWidgets('warning state shows resets info',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(used: 7500, limit: 10000, resetsIn: '1h 45m'),
      );

      expect(find.textContaining('Resets 1h 45m'), findsOneWidget);
    });
  });
}
