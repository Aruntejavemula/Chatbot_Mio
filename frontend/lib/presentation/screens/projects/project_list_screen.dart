import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        title: Text(
          'Projects',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            color: textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Your projects will appear here',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ),
    );
  }
}
