import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class ContextMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const ContextMenuItem({
    required this.label,
    this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

class ContextMenuWidget extends StatefulWidget {
  final Widget child;
  final List<ContextMenuItem> items;

  const ContextMenuWidget({
    super.key,
    required this.child,
    required this.items,
  });

  @override
  State<ContextMenuWidget> createState() => _ContextMenuWidgetState();
}

class _ContextMenuWidgetState extends State<ContextMenuWidget> {
  OverlayEntry? _overlayEntry;

  void _showMenu(Offset position) {
    _removeMenu();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        items: widget.items,
        onDismiss: _removeMenu,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) => _showMenu(details.globalPosition),
      onLongPressStart: (details) => _showMenu(details.globalPosition),
      child: widget.child,
    );
  }
}

class _ContextMenuOverlay extends StatelessWidget {
  final Offset position;
  final List<ContextMenuItem> items;
  final VoidCallback onDismiss;

  const _ContextMenuOverlay({
    required this.position,
    required this.items,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    // Adjust position to keep menu within screen bounds
    const menuWidth = 200.0;
    final menuHeight = items.length * 44.0 + 16.0;
    final dx =
        position.dx + menuWidth > screenSize.width
            ? screenSize.width - menuWidth - 8
            : position.dx;
    final dy =
        position.dy + menuHeight > screenSize.height
            ? screenSize.height - menuHeight - 8
            : position.dy;

    return Stack(
      children: [
        // Dismiss layer
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Menu
        Positioned(
          left: dx,
          top: dy,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: menuWidth,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSecondary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorderDefault
                      : AppColors.borderDefault,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items
                    .map((item) => _ContextMenuItemWidget(
                          item: item,
                          isDark: isDark,
                          onDismiss: onDismiss,
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuItemWidget extends StatelessWidget {
  final ContextMenuItem item;
  final bool isDark;
  final VoidCallback onDismiss;

  const _ContextMenuItemWidget({
    required this.item,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = item.isDestructive
        ? AppColors.error
        : isDark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary;

    return InkWell(
      onTap: () {
        onDismiss();
        item.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 18, color: textColor),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                item.label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
