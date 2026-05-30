import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

class PersonalizationPanel extends ConsumerStatefulWidget {
  const PersonalizationPanel({super.key});

  @override
  ConsumerState<PersonalizationPanel> createState() => _PersonalizationPanelState();
}

class _PersonalizationPanelState extends ConsumerState<PersonalizationPanel> {
  int _activeTab = 0; // 0 = Profile, 1 = Knowledge
  final _nicknameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _aboutController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _knowledgeSearchController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _occupationController.dispose();
    _aboutController.dispose();
    _instructionsController.dispose();
    _knowledgeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E4DE);
    final inputBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
          child: Row(
            children: [
              _tabButton('Profile', 0, textPrimary, textMuted),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tabButton('Knowledge', 1, textPrimary, textMuted),
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 14, color: textMuted),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Divider(color: borderColor, height: 1),
        ),
        Expanded(
          child: _activeTab == 0
              ? _buildProfileTab(textPrimary, textMuted, borderColor, inputBg, isDark)
              : _buildKnowledgeTab(textPrimary, textMuted, borderColor, inputBg, isDark),
        ),
      ],
    );
  }

  Widget _buildProfileTab(Color textPrimary, Color textMuted, Color borderColor, Color inputBg, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        // Nickname + Occupation row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nickname', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nicknameController,
                    style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                    decoration: _inputDecoration('What should Mio call you?', borderColor, inputBg, textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Occupation', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _occupationController,
                    style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                    decoration: _inputDecoration('e.g., Product Designer, Software Engineer', borderColor, inputBg, textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // More about you
        Text('More about you', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _aboutController,
          maxLines: 4,
          maxLength: 2000,
          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
          decoration: _inputDecoration(
            'Your background, preferences, or location to help Mio understand you better',
            borderColor, inputBg, textMuted,
          ).copyWith(
            counterStyle: GoogleFonts.dmSans(fontSize: 11, color: textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mio uses this information to personalize responses across all tasks.',
          style: GoogleFonts.dmSans(fontSize: 12, color: textMuted),
        ),
        const SizedBox(height: 24),
        // Custom Instructions
        Text('Custom Instructions', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: _instructionsController,
          maxLines: 4,
          maxLength: 3000,
          style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
          decoration: _inputDecoration(
            'How would you like Mio to respond?\ne.g., "Focus on Python best practices", "Maintain a professional tone", or "Always provide sources for important conclusions".',
            borderColor, inputBg, textMuted,
          ).copyWith(
            counterStyle: GoogleFonts.dmSans(fontSize: 11, color: textMuted),
          ),
        ),
        const SizedBox(height: 20),
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: () {
                _nicknameController.clear();
                _occupationController.clear();
                _aboutController.clear();
                _instructionsController.clear();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Cancel', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences saved')),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Save', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.black : Colors.white)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKnowledgeTab(Color textPrimary, Color textMuted, Color borderColor, Color inputBg, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        children: [
          // Search + Add
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _knowledgeSearchController,
                  style: GoogleFonts.dmSans(fontSize: 14, color: textPrimary),
                  decoration: _inputDecoration('Search Knowledge', borderColor, inputBg, textMuted).copyWith(
                    prefixIcon: Icon(Icons.search, size: 18, color: textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add knowledge — coming soon')),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Add', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w500)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Empty state
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lightbulb_outline, size: 40, color: textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('No knowledge entries yet', style: GoogleFonts.dmSans(fontSize: 14, color: textMuted)),
                  const SizedBox(height: 4),
                  Text('Add knowledge to help Mio remember important context', style: GoogleFonts.dmSans(fontSize: 12, color: textMuted.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color borderColor, Color inputBg, Color textMuted) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(fontSize: 13, color: textMuted.withValues(alpha: 0.7)),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.persian, width: 1.5),
      ),
    );
  }

  Widget _tabButton(String label, int index, Color textPrimary, Color textMuted) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }
}
