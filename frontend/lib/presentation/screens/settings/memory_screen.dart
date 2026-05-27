import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/memory_model.dart';
import '../../../data/services/memory_service.dart';
import '../../widgets/common/shaking_hands.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  final MemoryService _service = MemoryService();
  final TextEditingController _addController = TextEditingController();
  List<MemoryModel> _memories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _loadMemories() async {
    try {
      final memories = await _service.getMemories();
      if (mounted) setState(() { _memories = memories; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addMemory() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    try {
      await _service.addMemory(text);
      _addController.clear();
      await _loadMemories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save memory')),
        );
      }
    }
  }

  Future<void> _deleteMemory(String id) async {
    try {
      await _service.deleteMemory(id);
      await _loadMemories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete memory')),
        );
      }
    }
  }

  Future<void> _deleteAll() async {
    try {
      await _service.deleteAllMemories();
      await _loadMemories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to clear memories')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBgPrimary : AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Memory', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddSection(isDark),
                  const SizedBox(height: 24),
                  _buildMemoriesList(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildAddSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Column(
        children: [
          TextField(
            controller: _addController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'I prefer dark mode...',
              hintStyle: GoogleFonts.dmSans(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              border: InputBorder.none,
            ),
            style: GoogleFonts.dmSans(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addMemory,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.persian, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusFull))),
              child: Text('Save memory', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoriesList(bool isDark) {
    if (_memories.isEmpty) {
      return Center(
        child: Column(
          children: [
            const ShakingHands(size: 48),
            const SizedBox(height: 12),
            Text('No memories yet.', style: GoogleFonts.dmSans(fontSize: 14, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STORED MEMORIES', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted, letterSpacing: 1.2)),
            const Spacer(),
            TextButton(onPressed: _deleteAll, child: Text('Clear all', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.error))),
          ],
        ),
        const SizedBox(height: 8),
        ..._memories.map((m) => _buildMemoryCard(m, isDark)),
      ],
    );
  }

  Widget _buildMemoryCard(MemoryModel memory, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSecondary : AppColors.bgSecondary,
        border: Border.all(color: isDark ? AppColors.darkBorderDefault : AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memory.content, style: GoogleFonts.dmSans(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(memory.importanceLabel, style: GoogleFonts.dmSans(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
            onPressed: () => _deleteMemory(memory.id),
          ),
        ],
      ),
    );
  }
}
