import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../widgets/chat/file_upload_widget.dart';
import '../../widgets/chat/voice_input_widget.dart';

class ChatInputBar extends ConsumerStatefulWidget {
  final List<SelectedFileInfo> selectedFiles;
  final bool hasMessages;
  final void Function(String text, List<SelectedFileInfo> files) onSend;
  final VoidCallback onAttachFile;
  final VoidCallback onShowModelSelector;

  const ChatInputBar({
    super.key,
    required this.selectedFiles,
    required this.hasMessages,
    required this.onSend,
    required this.onAttachFile,
    required this.onShowModelSelector,
  });

  @override
  ConsumerState<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends ConsumerState<ChatInputBar>
    with TickerProviderStateMixin {
  late TextEditingController _inputController;
  late FocusNode _focusNode;
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isFocusedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isModelDropdownOpenNotifier = ValueNotifier(false);
  final ValueNotifier<String> _selectedModelNotifier = ValueNotifier('Think now');
  late AnimationController _sendButtonAnimController;

  bool get _isDesktop {
    if (kIsWeb) return false;
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _focusNode = FocusNode();
    _sendButtonAnimController = AnimationController(
      vsync: this,
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _focusNode.addListener(() {
      _isFocusedNotifier.value = _focusNode.hasFocus;
    });
    _inputController.addListener(() {
      _hasTextNotifier.value = _inputController.text.trim().isNotEmpty;
    });
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _sendButtonAnimController.dispose();
    _hasTextNotifier.dispose();
    _isFocusedNotifier.dispose();
    _isModelDropdownOpenNotifier.dispose();
    _selectedModelNotifier.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, widget.selectedFiles);
    _inputController.clear();
    _hasTextNotifier.value = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktopLayout = Responsive.isDesktop(context) ||
        (Responsive.isTablet(context) && Responsive.isLandscape(context));

    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final inputBg = isDark ? const Color(0xFF141414) : const Color(0xFFF0ECE5);
    final desktopInputBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final desktopBorder = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2);
    final hintText = (isDesktopLayout && widget.hasMessages) ? 'Reply...' : 'How can I help you today?';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.black : AppColors.bgPrimary,
      ),
      padding: EdgeInsets.fromLTRB(
        isDesktopLayout ? 0 : 16,
        8,
        isDesktopLayout ? 0 : 16,
        isDesktopLayout ? 0 : 8 + MediaQuery.of(context).viewPadding.bottom,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _isFocusedNotifier,
        builder: (context, isFocused, child) {
          final borderColor = isFocused
              ? AppColors.persian.withValues(alpha: 0.4)
              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2));
          final effectiveInputBg = isDesktopLayout ? desktopInputBg : inputBg;
          final effectiveBorder = isDesktopLayout
              ? (isFocused ? AppColors.persian.withValues(alpha: 0.4) : desktopBorder)
              : borderColor;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: effectiveInputBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: effectiveBorder, width: 1),
              boxShadow: isDesktopLayout
                  ? [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (_isDesktop && event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        if (!HardwareKeyboard.instance.isShiftPressed) {
                          _sendMessage();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: GoogleFonts.dmSans(fontSize: 15, color: textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.dmSans(fontSize: 15, color: textPrimary),
                      maxLines: 6,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      onChanged: (value) => _hasTextNotifier.value = value.trim().isNotEmpty,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 10, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: widget.onAttachFile,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.add, size: 22, color: textMuted),
                        ),
                      ),
                      const Spacer(),
                      // Desktop: model selector inside input bar
                      if (isDesktopLayout) ...[
                        GestureDetector(
                          onTap: () {
                            _isModelDropdownOpenNotifier.value = !_isModelDropdownOpenNotifier.value;
                            widget.onShowModelSelector();
                          },
                          child: ValueListenableBuilder<String>(
                            valueListenable: _selectedModelNotifier,
                            builder: (context, selectedModel, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F2ED),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedModel == 'Think now' ? 'Select model' : selectedModel,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _isModelDropdownOpenNotifier,
                                      builder: (context, isOpen, child) {
                                        return AnimatedRotation(
                                          turns: isOpen ? 0.5 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: textMuted,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ValueListenableBuilder<bool>(
                        valueListenable: _hasTextNotifier,
                        builder: (context, hasText, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!hasText) ...[
                                VoiceInputWidget(
                                  onTranscript: (text) {
                                    _inputController.text = text;
                                    _hasTextNotifier.value = text.isNotEmpty;
                                  },
                                  onCancel: () {},
                                ),
                                const SizedBox(width: 8),
                              ],
                              AnimatedBuilder(
                                animation: _sendButtonAnimController,
                                builder: (context, child) {
                                  return GestureDetector(
                                    onTapDown: hasText
                                        ? (_) => _sendButtonAnimController.animateTo(
                                            0.88,
                                            duration: const Duration(milliseconds: 150),
                                            curve: Curves.easeOut,
                                          )
                                        : null,
                                    onTapUp: hasText
                                        ? (_) {
                                            final sim = SpringSimulation(
                                              MioAnimations.spring,
                                              _sendButtonAnimController.value,
                                              1.0,
                                              0,
                                            );
                                            _sendButtonAnimController.animateWith(sim);
                                            _sendMessage();
                                          }
                                        : null,
                                    onTapCancel: hasText
                                        ? () {
                                            final sim = SpringSimulation(
                                              MioAnimations.spring,
                                              _sendButtonAnimController.value,
                                              1.0,
                                              0,
                                            );
                                            _sendButtonAnimController.animateWith(sim);
                                          }
                                        : null,
                                    child: Transform.scale(
                                      scale: _sendButtonAnimController.value,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(17),
                                          color: hasText
                                              ? (isDark ? Colors.white : const Color(0xFF1A1814))
                                              : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFD6D0C6)),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: hasText
                                                ? (isDark ? Colors.black : Colors.white)
                                                : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
