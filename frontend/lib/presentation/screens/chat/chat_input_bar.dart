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
  final String selectedModel;
  final List<Map<String, dynamic>> availableModels;
  final void Function(String text, List<SelectedFileInfo> files) onSend;
  final VoidCallback onAttachFile;
  final void Function(String model, String provider) onModelSelected;

  const ChatInputBar({
    super.key,
    required this.selectedFiles,
    required this.hasMessages,
    required this.selectedModel,
    required this.availableModels,
    required this.onSend,
    required this.onAttachFile,
    required this.onModelSelected,
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
  late AnimationController _sendButtonAnimController;
  final LayerLink _menuLink = LayerLink();
  final LayerLink _modelLink = LayerLink();
  OverlayEntry? _menuOverlay;
  OverlayEntry? _modelOverlay;
  bool _isMenuOpen = false;
  bool _isModelOpen = false;
  late AnimationController _glowController;
  Animation<Color?>? _glowAnimation;

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
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    _glowController.dispose();
    _hasTextNotifier.dispose();
    _isFocusedNotifier.dispose();
    _isModelDropdownOpenNotifier.dispose();
    _closeAllOverlays();
    super.dispose();
  }

  void _closeAllOverlays() {
    if (_isMenuOpen) {
      _menuOverlay?.remove();
      _menuOverlay = null;
      _isMenuOpen = false;
    }
    if (_isModelOpen) {
      _modelOverlay?.remove();
      _modelOverlay = null;
      _isModelOpen = false;
      _isModelDropdownOpenNotifier.value = false;
    }
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _menuOverlay?.remove();
      _menuOverlay = null;
      _isMenuOpen = false;
    } else {
      _closeAllOverlays();
      _menuOverlay = _createMenuOverlay();
      Overlay.of(context).insert(_menuOverlay!);
      _isMenuOpen = true;
    }
  }

  void _toggleModelDropdown() {
    if (_isModelOpen) {
      _modelOverlay?.remove();
      _modelOverlay = null;
      _isModelOpen = false;
      _isModelDropdownOpenNotifier.value = false;
    } else {
      _closeAllOverlays();
      _modelOverlay = _createModelOverlay();
      Overlay.of(context).insert(_modelOverlay!);
      _isModelOpen = true;
      _isModelDropdownOpenNotifier.value = true;
    }
  }

  OverlayEntry _createMenuOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF262626) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final divider = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E2DA);

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _closeAllOverlays,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _menuLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -340),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _menuItem(Icons.attach_file, 'Add files or photos', textPrimary, textMuted, () {
                            _closeAllOverlays();
                            widget.onAttachFile();
                          }),
                          _menuItem(Icons.folder_outlined, 'Add to project', textPrimary, textMuted, () {}, hasChevron: true),
                          _menuItem(Icons.construction_outlined, 'Skills', textPrimary, textMuted, () {}, hasChevron: true),
                          _menuItem(Icons.power_outlined, 'Connectors', textPrimary, textMuted, () {}, hasChevron: true),
                          _menuItem(Icons.extension_outlined, 'Plugins', textPrimary, textMuted, () {}, hasChevron: true),
                          Divider(height: 1, color: divider, indent: 48),
                          _menuItem(Icons.search_outlined, 'Research', textPrimary, textMuted, () {}),
                          _menuItem(Icons.language_outlined, 'Web search', textPrimary, textMuted, () {}, trailing: const Icon(Icons.check, size: 18, color: Color(0xFF4285F4))),
                          _menuItem(Icons.brush_outlined, 'Use style', textPrimary, textMuted, () {}, hasChevron: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  OverlayEntry _createModelOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final bg = isDark ? const Color(0xFF262626) : Colors.white;

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _closeAllOverlays,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _modelLink,
                showWhenUnlinked: false,
                offset: const Offset(-200, -320),
                child: GestureDetector(
                  onTap: () {},
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 280,
                      constraints: const BoxConstraints(maxHeight: 340),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: widget.availableModels.length + 1,
                        itemBuilder: (context, index) {
                          if (index == widget.availableModels.length) {
                            return GestureDetector(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.expand_more, size: 18, color: textMuted),
                                    const SizedBox(width: 12),
                                    Text(
                                      'More models',
                                      style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w500),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.chevron_right, size: 18, color: textMuted),
                                  ],
                                ),
                              ),
                            );
                          }
                          final model = widget.availableModels[index];
                          final isSelected = widget.selectedModel == model['model'];
                          return GestureDetector(
                            onTap: () {
                              widget.onModelSelected(
                                model['model'] as String,
                                model['provider'] as String,
                              );
                              _closeAllOverlays();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: model['color'] as Color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          model['model'] as String,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            color: textPrimary,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          model['description'] as String,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: textMuted,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check, size: 18, color: Color(0xFF4285F4)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _menuItem(IconData icon, String label, Color textPrimary, Color textMuted, VoidCallback onTap, {bool hasChevron = false, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary, fontWeight: FontWeight.w400),
              ),
            ),
            if (trailing != null) trailing,
            if (hasChevron) Icon(Icons.chevron_right, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Gemini-style glow burst
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _glowAnimation = ColorTween(
      begin: AppColors.persian,
      end: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0DBD2),
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    _glowController.forward(from: 0);

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
        color: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
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
                      // + menu button
                      CompositedTransformTarget(
                        link: _menuLink,
                        child: GestureDetector(
                          onTap: _toggleMenu,
                          child: AnimatedRotation(
                            turns: _isMenuOpen ? 0.125 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.add, size: 22, color: textMuted),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Model selector (always shown, like Claude)
                      CompositedTransformTarget(
                        link: _modelLink,
                        child: GestureDetector(
                          onTap: _toggleModelDropdown,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _isModelDropdownOpenNotifier,
                            builder: (context, isOpen, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.selectedModel == 'Think now' ? 'Select model' : widget.selectedModel,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedRotation(
                                    turns: isOpen ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mic / Send
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
                                      child: AnimatedBuilder(
                                        animation: _glowController,
                                        builder: (context, child) {
                                          final glowColor = _glowAnimation?.value;
                                          return Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(17),
                                              color: hasText
                                                  ? AppColors.persian
                                                  : (isDark ? const Color(0xFF3A3530) : const Color(0xFF8A8078)),
                                              boxShadow: glowColor != null
                                                  ? [
                                                      BoxShadow(
                                                        color: glowColor.withValues(
                                                          alpha: (1.0 - _glowController.value) * 0.6,
                                                        ),
                                                        blurRadius: 18 + _glowController.value * 12,
                                                        spreadRadius: 2 + _glowController.value * 4,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Center(
                                          child: Icon(
                                            Icons.arrow_upward_rounded,
                                            size: 18,
                                            color: hasText ? Colors.white : textMuted,
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
