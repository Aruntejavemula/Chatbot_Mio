import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/animations.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../widgets/chat/document_viewer_widget.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/common/shaking_hands.dart';

class ChatEmptyState extends ConsumerWidget {
  final bool isDark;
  final bool isDesktop;
  final List<SelectedFileInfo> selectedFiles;
  final ValueChanged<int> onRemoveFile;
  final Widget inputBar;
  final ValueChanged<String>? onSuggestionTap;
  final VoidCallback? onTapBackground;

  const ChatEmptyState({
    super.key,
    required this.isDark,
    required this.isDesktop,
    required this.selectedFiles,
    required this.onRemoveFile,
    required this.inputBar,
    this.onSuggestionTap,
    this.onTapBackground,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);

    if (!isDesktop) {
      // Mobile: simple mascot + greeting + input bar at bottom
      return Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                onTapBackground?.call();
                FocusScope.of(context).unfocus();
              },
              behavior: HitTestBehavior.translucent,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FadeSlideIn(
                        duration: MioAnimations.slow,
                        child: ShakingHands(size: 48, animate: false),
                      ),
                      const SizedBox(height: 24),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        duration: MioAnimations.slow,
                        child: Text(
                          _getTimeGreeting(),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 28,
                            height: 1.3,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (selectedFiles.isNotEmpty)
            DocumentViewerWidget(
              files: selectedFiles,
              onRemoveFile: onRemoveFile,
              isDark: isDark,
            ),
          inputBar,
        ],
      );
    }

    // Desktop: Claude-style centered greeting + input with model selector + suggestion pills
    final currentUser = ref.watch(currentUserProvider);
    final userName = currentUser?.name;
    final hasName = userName != null && userName.isNotEmpty;
    final firstName = hasName ? userName.split(' ').first : '';

    return GestureDetector(
      onTap: () {
        onTapBackground?.call();
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Greeting with mascot inline
                      FadeSlideIn(
                        duration: MioAnimations.slow,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const ShakingHands(size: 40, animate: true),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _getDesktopGreeting(firstName),
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 32,
                                  height: 1.2,
                                  color: textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Input bar with model selector inside
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        duration: MioAnimations.slow,
                        child: inputBar,
                      ),
                      const SizedBox(height: 16),
                      // Suggestion pills
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 350),
                        duration: MioAnimations.slow,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _desktopSuggestionPill(Icons.edit_outlined, 'Write', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.auto_awesome_outlined, 'Learn', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.code, 'Code', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.home_outlined, 'Life stuff', textPrimary, textMuted, isDark),
                            _desktopSuggestionPill(Icons.lightbulb_outline, "Mio's choice", textPrimary, textMuted, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSuggestionPill(IconData icon, String label, Color textPrimary, Color textMuted, bool isDark) {
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final border = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);
    return ScaleTap(
      onTap: () => onSuggestionTap?.call(label),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: MioAnimations.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDesktopGreeting(String name) {
    final hour = DateTime.now().hour;
    final suffix = name.isNotEmpty ? ', $name' : '';
    if (hour >= 5 && hour < 12) return 'Good morning$suffix';
    if (hour >= 12 && hour < 17) return 'Good afternoon$suffix';
    if (hour >= 17 && hour < 21) return 'Good evening$suffix';
    return 'Good evening$suffix';
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'How can I help you\nthis morning?';
    if (hour >= 12 && hour < 17) return 'How can I help you\nthis afternoon?';
    if (hour >= 17 && hour < 21) return 'How can I help you\nthis evening?';
    return 'How can I help you\nthis late night?';
  }
}
