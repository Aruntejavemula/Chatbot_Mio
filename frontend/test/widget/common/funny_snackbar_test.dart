import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/presentation/widgets/common/funny_snackbar.dart';

void main() {
  group('FunnySnackbar', () {
    Widget buildTestApp({required Widget child}) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    testWidgets('show() displays message text in a SnackBar',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                FunnySnackbar.show(context, 'Test message');
              },
              child: const Text('Show'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('show() with SnackbarType.error displays message',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                FunnySnackbar.show(
                  context,
                  'Error occurred',
                  type: SnackbarType.error,
                );
              },
              child: const Text('Show Error'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Error occurred'), findsOneWidget);
    });

    testWidgets('show() with SnackbarType.warning displays message',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                FunnySnackbar.show(
                  context,
                  'Warning message',
                  type: SnackbarType.warning,
                );
              },
              child: const Text('Show Warning'),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.text('Warning message'), findsOneWidget);
    });

    testWidgets('show() clears existing snackbars before showing new one',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(
        child: Builder(
          builder: (context) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    FunnySnackbar.show(context, 'First message');
                  },
                  child: const Text('First'),
                ),
                ElevatedButton(
                  onPressed: () {
                    FunnySnackbar.show(context, 'Second message');
                  },
                  child: const Text('Second'),
                ),
              ],
            );
          },
        ),
      ));

      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();
      expect(find.text('First message'), findsOneWidget);

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(find.text('Second message'), findsOneWidget);
    });
  });
}
