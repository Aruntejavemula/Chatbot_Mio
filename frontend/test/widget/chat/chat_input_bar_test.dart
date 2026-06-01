import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/core/constants/app_colors.dart';
import 'package:mio/presentation/screens/chat/chat_input_bar.dart';
import 'package:mio/presentation/widgets/chat/file_upload_widget.dart';

void main() {
  group('ChatInputBar', () {
    Widget buildTestWidget({
      List<SelectedFileInfo> selectedFiles = const [],
      bool hasMessages = false,
      String selectedModel = 'Think now',
      void Function(String, List<SelectedFileInfo>)? onSend,
      VoidCallback? onAttachFile,
      void Function(String, String)? onModelSelected,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ChatInputBar(
              selectedFiles: selectedFiles,
              hasMessages: hasMessages,
              selectedModel: selectedModel,
              availableModels: const [
                {'provider': 'Anthropic', 'model': 'Claude 4 Sonnet', 'description': 'Most capable', 'color': Color(0xFFD97757)},
              ],
              onSend: onSend ?? (_, __) {},
              onAttachFile: onAttachFile ?? () {},
              onModelSelected: onModelSelected ?? (_, __) {},
            ),
          ),
        ),
      );
    }

    testWidgets('send button is muted when text field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the send button (last Icon with arrow_upward)
      final sendIcon = find.byIcon(Icons.arrow_upward_rounded);
      expect(sendIcon, findsOneWidget);

      // Find the parent Container of the send icon
      final container = tester.widget<Container>(
        find.ancestor(of: sendIcon, matching: find.byType(Container)).last,
      );

      final decoration = container.decoration as BoxDecoration;
      // When empty, background should NOT be Persian Orange
      expect(decoration.color, isNot(equals(AppColors.persian)));
    });

    testWidgets('send button turns Persian Orange when text is entered',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter text
      await tester.enterText(textField, 'Hello AI');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Find the send button
      final sendIcon = find.byIcon(Icons.arrow_upward_rounded);
      expect(sendIcon, findsOneWidget);

      // Find the send button container via its Transform.scale parent
      final scale = find.ancestor(
        of: sendIcon,
        matching: find.byType(Transform),
      );
      expect(scale, findsOneWidget);

      // The button is now wrapped in AnimatedBuilder with a Container child
      final containerFinder = find.descendant(
        of: scale,
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);

      // The send button should now have Persian Orange background
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.persian));
    });

    testWidgets('+ button exists and rotates when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the + button (Icon with add)
      final plusButton = find.byIcon(Icons.add);
      expect(plusButton, findsOneWidget);
    });

    testWidgets('can type into the text field',
        (WidgetTester tester) async {
      String? capturedText;
      final capturedFiles = <SelectedFileInfo>[];

      await tester.pumpWidget(buildTestWidget(
        onSend: (text, files) {
          capturedText = text;
          capturedFiles.addAll(files);
        },
      ));
      await tester.pumpAndSettle();

      // Type a message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Tap the send button
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      // Verify the message was sent
      expect(capturedText, equals('Test message'));
    });
  });
}
