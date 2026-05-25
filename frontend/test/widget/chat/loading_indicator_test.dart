import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/presentation/widgets/chat/loading_indicator.dart';

void main() {
  group('LoadingIndicator', () {
    Widget buildTestWidget(LoadingState state,
        {String word = '', String streamingText = ''}) {
      return MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(
            state: state,
            word: word,
            streamingText: streamingText,
          ),
        ),
      );
    }

    testWidgets('idle state renders SizedBox.shrink',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));

      // SizedBox.shrink() has zero size
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('thinking state does not render SizedBox.shrink',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(LoadingState.thinking));
      // Advance past all pending Future.delayed timers (150ms + 300ms)
      // and ensure dot animation controllers are started
      await tester.pump(const Duration(milliseconds: 350));

      // The widget should not be a zero-size SizedBox
      expect(find.byType(LoadingIndicator), findsOneWidget);

      // Verify it renders a Padding (the main container) not SizedBox.shrink
      expect(find.byType(Padding), findsWidgets);

      // Switch to idle and pump past any remaining timers
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('responding state shows word text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(LoadingState.responding, word: 'Analyzing'),
      );
      // Advance to let the word fade animation play and Future.delayed fire
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Analyzing...'), findsOneWidget);

      // Switch to idle and pump past timers
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('streaming state shows streaming text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          LoadingState.streaming,
          streamingText: 'Generating response...',
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Generating response...'), findsOneWidget);

      // Switch to idle to stop cursor animation
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('transitions from idle to thinking and back to idle',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));

      // Verify idle shows nothing
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 0.0);

      // Switch to thinking and pump past delayed Future timers
      await tester.pumpWidget(buildTestWidget(LoadingState.thinking));
      await tester.pump(const Duration(milliseconds: 350));

      // Should show the indicator (Padding wrapping content)
      expect(find.byType(LoadingIndicator), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);

      // Switch back to idle to stop animations, pump past remaining timers
      await tester.pumpWidget(buildTestWidget(LoadingState.idle));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify returns to SizedBox.shrink
      final sizedBox2 = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox2.width, 0.0);
      expect(sizedBox2.height, 0.0);
    });
  });
}
