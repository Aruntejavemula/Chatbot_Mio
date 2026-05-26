import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio/data/models/message_model.dart';
import 'package:mio/presentation/widgets/chat/chat_bubble.dart';

void main() {
  group('ChatBubble', () {
    Widget buildTestWidget(MessageModel message,
        {String? thinkingContent}) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatBubble(
              message: message,
              isLast: true,
              thinkingContent: thinkingContent,
            ),
          ),
        ),
      );
    }

    testWidgets('renders user message aligned right with content',
        (WidgetTester tester) async {
      final message = MessageModel(
        id: 'msg-user-1',
        chatId: 'chat-1',
        role: 'user',
        content: 'Hello from user',
        createdAt: DateTime.utc(2024, 1, 15, 10, 30),
      );

      await tester.pumpWidget(buildTestWidget(message));
      await tester.pumpAndSettle();

      // User message content should be visible
      expect(find.text('Hello from user'), findsOneWidget);

      // User messages should align right (Alignment.centerRight)
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerRight);
    });

    testWidgets('renders AI message aligned left with model name',
        (WidgetTester tester) async {
      final message = MessageModel(
        id: 'msg-ai-1',
        chatId: 'chat-1',
        role: 'assistant',
        content: 'Hello from AI',
        createdAt: DateTime.utc(2024, 1, 15, 10, 31),
        model: 'gpt-4o',
      );

      await tester.pumpWidget(buildTestWidget(message));
      await tester.pumpAndSettle();

      // AI message should show model name
      expect(find.text('gpt-4o'), findsOneWidget);

      // AI messages should align left
      final align = tester.widget<Align>(find.byType(Align).first);
      expect(align.alignment, Alignment.centerLeft);
    });

    testWidgets('AI message displays content',
        (WidgetTester tester) async {
      final message = MessageModel(
        id: 'msg-ai-2',
        chatId: 'chat-1',
        role: 'assistant',
        content: 'This is the AI response text',
        createdAt: DateTime.utc(2024, 1, 15, 10, 32),
        model: 'claude-sonnet-4-5',
      );

      await tester.pumpWidget(buildTestWidget(message));
      await tester.pumpAndSettle();

      expect(find.text('claude-sonnet-4-5'), findsOneWidget);
      // The markdown body renders the text
      expect(find.textContaining('AI response text'), findsOneWidget);
    });

    testWidgets('user message shows time stamp',
        (WidgetTester tester) async {
      final message = MessageModel(
        id: 'msg-user-ts',
        chatId: 'chat-1',
        role: 'user',
        content: 'Time test',
        createdAt: DateTime(2024, 1, 15, 14, 30), // 2:30 PM
      );

      await tester.pumpWidget(buildTestWidget(message));
      await tester.pumpAndSettle();

      // Should show formatted time
      expect(find.textContaining('2:30'), findsOneWidget);
    });
  });
}
