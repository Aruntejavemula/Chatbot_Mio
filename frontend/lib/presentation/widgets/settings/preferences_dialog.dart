import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/animations.dart';
import 'panels/account_panel.dart';
import 'panels/billing_panel.dart';
import 'panels/connectors_panel.dart';
import 'panels/data_controls_panel.dart';
import 'panels/integrations_panel.dart';
import 'panels/mail_mio_panel.dart';
import 'panels/personalization_panel.dart';
import 'panels/scheduled_tasks_panel.dart';
import 'panels/settings_panel.dart';
import 'panels/usage_panel.dart';

enum PreferencesSection {
  account,
  settings,
  usage,
  billing,
  scheduledTasks,
  mailMio,
  dataControls,
  personalization,
  connectors,
  integrations,
}

class PreferencesDialog extends ConsumerStatefulWidget {
  final PreferencesSection initialSection;
  const PreferencesDialog({super.key, this.initialSection = PreferencesSection.account});

  static Future<void> show(BuildContext context,
      {PreferencesSection initialSection = PreferencesSection.account}) {
    return showMioModal(
      context: context,
      builder: (_) => PreferencesDialog(initialSection: initialSection),
    );
  }

  @override
  ConsumerState<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends ConsumerState<PreferencesDialog> {
  late PreferencesSection _selected = widget.initialSection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.72).clamp(640.0, 960.0);
    final dialogHeight = (size.height * 0.78).clamp(480.0, 720.0);

    final bg = isDark ? const Color(0xFF141414) : Colors.white;
    final navBg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAF8F5);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                _buildNav(isDark, navBg, borderColor),
                Expanded(child: _buildContentArea(isDark, borderColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNav(bool isDark, Color navBg, Color borderColor) {
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: navBg,
        border: Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_outlined, size: 20, color: AppColors.persian),
                const SizedBox(width: 8),
                Text(
                  'Mio',
                  style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: textPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _navItem(PreferencesSection.account, Icons.person_outline, 'Account', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.settings, Icons.settings_outlined, 'Settings', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.usage, Icons.bar_chart_outlined, 'Usage', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.billing, Icons.credit_card_outlined, 'Billing', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.scheduledTasks, Icons.schedule_outlined, 'Scheduled tasks', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.mailMio, Icons.mail_outline, 'Mail Mio', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.dataControls, Icons.shield_outlined, 'Data controls', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.personalization, Icons.dashboard_customize_outlined, 'Personalization', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.connectors, Icons.cable_outlined, 'Connectors', textPrimary, textMuted, isDark),
                _navItem(PreferencesSection.integrations, Icons.extension_outlined, 'Integrations', textPrimary, textMuted, isDark),
                const SizedBox(height: 8),
                Divider(color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE), height: 1),
                const SizedBox(height: 8),
                _navItem(null, Icons.help_outline, 'Get help', textPrimary, textMuted, isDark, isExternal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    PreferencesSection? section,
    IconData icon,
    String label,
    Color textPrimary,
    Color textMuted,
    bool isDark, {
    bool isExternal = false,
  }) {
    final isActive = section != null && _selected == section;
    final activeBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEEEBE5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0EDE7),
          onTap: () {
            if (isExternal) return;
            if (section != null) setState(() => _selected = section);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(icon, size: 18, color: isActive ? textPrimary : textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? textPrimary : textMuted,
                    ),
                  ),
                ),
                if (isExternal)
                  Icon(Icons.open_in_new, size: 14, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(bool isDark, Color borderColor) {
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 18, 16, 0),
          child: Row(
            children: [
              Text(
                _sectionTitle(_selected),
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: textPrimary),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: isDark ? const Color(0xFF888888) : const Color(0xFF666666)),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 18,
              ),
            ],
          ),
        ),
        if (_sectionSubtitle(_selected) != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 2, 28, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _sectionSubtitle(_selected)!,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF888888) : const Color(0xFF888888),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Divider(color: borderColor, height: 1),
        Expanded(
          child: AnimatedSwitcher(
            duration: MioAnimations.fast,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey<PreferencesSection>(_selected),
              child: _buildPanel(),
            ),
          ),
        ),
      ],
    );
  }

  String _sectionTitle(PreferencesSection section) {
    switch (section) {
      case PreferencesSection.account:
        return 'Account';
      case PreferencesSection.settings:
        return 'Settings';
      case PreferencesSection.usage:
        return 'Usage';
      case PreferencesSection.billing:
        return 'Billing Dashboard';
      case PreferencesSection.scheduledTasks:
        return 'Scheduled tasks';
      case PreferencesSection.mailMio:
        return 'Mail Mio';
      case PreferencesSection.dataControls:
        return 'Data controls';
      case PreferencesSection.personalization:
        return 'Personalization';
      case PreferencesSection.connectors:
        return 'Connectors';
      case PreferencesSection.integrations:
        return 'Integrations';
    }
  }

  String? _sectionSubtitle(PreferencesSection section) {
    switch (section) {
      case PreferencesSection.billing:
        return 'Manage your subscription and credits';
      case PreferencesSection.personalization:
        return 'Manage who you are and what Mio remembers';
      case PreferencesSection.integrations:
        return 'Build workflows across your favorite apps';
      default:
        return null;
    }
  }

  Widget _buildPanel() {
    switch (_selected) {
      case PreferencesSection.account:
        return const AccountPanel();
      case PreferencesSection.settings:
        return const SettingsPanel();
      case PreferencesSection.usage:
        return const UsagePanel();
      case PreferencesSection.billing:
        return const BillingPanel();
      case PreferencesSection.scheduledTasks:
        return const ScheduledTasksPanel();
      case PreferencesSection.mailMio:
        return const MailMioPanel();
      case PreferencesSection.dataControls:
        return const DataControlsPanel();
      case PreferencesSection.personalization:
        return const PersonalizationPanel();
      case PreferencesSection.connectors:
        return const ConnectorsPanel();
      case PreferencesSection.integrations:
        return const IntegrationsPanel();
    }
  }
}
