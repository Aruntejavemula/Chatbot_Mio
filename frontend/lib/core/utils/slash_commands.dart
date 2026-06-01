import 'package:flutter/material.dart';

/// A Claude Code / Devin style slash command available in the chat input.
class SlashCommand {
  /// Command token, including the leading slash, e.g. `/init`.
  final String name;

  /// Short one-line description shown in the autocomplete menu.
  final String description;

  /// Placeholder hint for the argument the command expects (may be empty).
  final String hint;

  /// Icon shown in the autocomplete menu.
  final IconData icon;

  /// Whether the command needs an argument typed after it before it runs.
  final bool needsArgument;

  const SlashCommand({
    required this.name,
    required this.description,
    required this.icon,
    this.hint = '',
    this.needsArgument = false,
  });
}

/// All slash commands supported by the chat input.
const List<SlashCommand> kSlashCommands = [
  SlashCommand(
    name: '/init',
    description: 'Research and learn the codebase',
    icon: Icons.travel_explore_outlined,
    hint: 'optional path or focus area',
  ),
  SlashCommand(
    name: '/implement',
    description: 'Plan and implement a feature',
    icon: Icons.build_outlined,
    hint: 'describe the feature',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/research',
    description: 'Deep-research a topic or question',
    icon: Icons.science_outlined,
    hint: 'what to research',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/learn',
    description: 'Explain and teach a concept',
    icon: Icons.school_outlined,
    hint: 'topic to learn',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/explain',
    description: 'Explain code or how something works',
    icon: Icons.menu_book_outlined,
    hint: 'code or file to explain',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/fix',
    description: 'Diagnose and fix a bug',
    icon: Icons.bug_report_outlined,
    hint: 'describe the bug',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/test',
    description: 'Generate tests for code',
    icon: Icons.checklist_outlined,
    hint: 'what to test',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/review',
    description: 'Review code or changes',
    icon: Icons.rate_review_outlined,
    hint: 'what to review',
    needsArgument: true,
  ),
  SlashCommand(
    name: '/help',
    description: 'List all available commands',
    icon: Icons.help_outline,
  ),
  SlashCommand(
    name: '/clear',
    description: 'Clear the current conversation',
    icon: Icons.delete_sweep_outlined,
  ),
];

/// Result of parsing a raw input string for a slash command.
class SlashParseResult {
  final SlashCommand command;
  final String argument;
  const SlashParseResult(this.command, this.argument);
}

/// Parses [text] and returns the matching command + argument, or null if the
/// text does not begin with a known slash command.
SlashParseResult? parseSlashCommand(String text) {
  final trimmed = text.trimLeft();
  if (!trimmed.startsWith('/')) return null;
  final spaceIdx = trimmed.indexOf(' ');
  final token = spaceIdx == -1 ? trimmed : trimmed.substring(0, spaceIdx);
  final arg = spaceIdx == -1 ? '' : trimmed.substring(spaceIdx + 1).trim();
  for (final c in kSlashCommands) {
    if (c.name.toLowerCase() == token.toLowerCase()) {
      return SlashParseResult(c, arg);
    }
  }
  return null;
}

/// Builds the assistant response body for a slash command so that running a
/// command always produces a meaningful, related result in the chat.
String slashCommandResponse(SlashCommand command, String argument) {
  final arg = argument.trim();
  switch (command.name) {
    case '/init':
      final scope = arg.isEmpty ? 'this project' : '`$arg`';
      return 'Initializing — researching and learning $scope.\n\n'
          'Here is how I will approach it:\n'
          '1. Map the project structure (entry points, modules, key folders).\n'
          '2. Identify the tech stack, frameworks, and conventions in use.\n'
          '3. Trace the main data flow and how features connect.\n'
          '4. Note build, run, and test commands.\n'
          '5. Summarize what I learned and suggest where to start.\n\n'
          'Tip: connect a repository or add files so I can read the real code.';
    case '/implement':
      if (arg.isEmpty) {
        return 'Tell me what to implement, e.g. `/implement a dark-mode toggle`.';
      }
      return 'Implementing: "$arg".\n\n'
          'Plan:\n'
          '1. Clarify requirements and edge cases.\n'
          '2. Locate the files and components involved.\n'
          '3. Write the change following existing patterns.\n'
          '4. Add tests and verify.\n'
          '5. Summarize the diff for review.';
    case '/research':
      if (arg.isEmpty) {
        return 'What should I research? e.g. `/research vector databases`.';
      }
      return 'Researching: "$arg".\n\n'
          'I will gather background, compare approaches, list trade-offs, and '
          'finish with a concise recommendation and sources.';
    case '/learn':
      if (arg.isEmpty) {
        return 'What would you like to learn? e.g. `/learn how Riverpod works`.';
      }
      return 'Let us learn: "$arg".\n\n'
          'I will start from the fundamentals, build up with examples, and end '
          'with a short recap and practice ideas.';
    case '/explain':
      if (arg.isEmpty) {
        return 'Paste code or name a file after `/explain` and I will break it down.';
      }
      return 'Explaining: "$arg".\n\n'
          'I will walk through what it does, line by line where useful, call out '
          'gotchas, and suggest improvements.';
    case '/fix':
      if (arg.isEmpty) {
        return 'Describe the bug after `/fix` (error message, expected vs actual).';
      }
      return 'Fixing: "$arg".\n\n'
          'I will reproduce the issue, find the root cause, propose a fix, and '
          'confirm it does not break related behavior.';
    case '/test':
      if (arg.isEmpty) {
        return 'Name what to test after `/test`, e.g. `/test the auth service`.';
      }
      return 'Generating tests for: "$arg".\n\n'
          'I will cover the happy path, edge cases, and failure modes, matching '
          'your existing test framework.';
    case '/review':
      if (arg.isEmpty) {
        return 'Point me at code or changes after `/review` and I will assess them.';
      }
      return 'Reviewing: "$arg".\n\n'
          'I will check correctness, readability, performance, and security, then '
          'list prioritized, actionable feedback.';
    case '/help':
      final lines = kSlashCommands
          .map((c) => '• ${c.name} — ${c.description}')
          .join('\n');
      return 'Available commands:\n\n$lines\n\n'
          'Type `/` in the message box to see this menu inline.';
    default:
      return 'Running ${command.name}.';
  }
}
