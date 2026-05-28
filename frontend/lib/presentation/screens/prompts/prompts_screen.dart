import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class _PromptItem {
  final String title;
  final String description;
  final Color bgColor;
  final IconData icon;
  final List<String> categories;

  const _PromptItem({
    required this.title,
    required this.description,
    required this.bgColor,
    required this.icon,
    required this.categories,
  });
}

const _inspirationPrompts = <_PromptItem>[
  _PromptItem(
    title: 'Writing Editor',
    description: 'Polish your writing with grammar fixes, better word choices, and clearer structure.',
    bgColor: Color(0xFFE8F5E9),
    icon: Icons.edit_note,
    categories: ['All', 'Be creative'],
  ),
  _PromptItem(
    title: 'Code Reviewer',
    description: 'Get instant code reviews with suggestions for performance, readability, and best practices.',
    bgColor: Color(0xFF1A1A2E),
    icon: Icons.code,
    categories: ['All', 'Learn something'],
  ),
  _PromptItem(
    title: 'Brainstorm Ideas',
    description: 'Generate creative ideas for projects, content, business plans, or any topic.',
    bgColor: Color(0xFFE3F2FD),
    icon: Icons.lightbulb_outline,
    categories: ['All', 'Be creative'],
  ),
  _PromptItem(
    title: 'Flashcards',
    description: 'Create study flashcards from any topic. Perfect for exam prep and learning new subjects.',
    bgColor: Color(0xFFBBDEFB),
    icon: Icons.quiz_outlined,
    categories: ['All', 'Learn something'],
  ),
  _PromptItem(
    title: 'Language Tutor',
    description: 'Practice conversations in any language with corrections and vocabulary tips.',
    bgColor: Color(0xFFF3E5F5),
    icon: Icons.translate,
    categories: ['All', 'Learn something'],
  ),
  _PromptItem(
    title: 'Meal Planner',
    description: 'Plan weekly meals based on your diet, preferences, and available ingredients.',
    bgColor: Color(0xFFFFF3E0),
    icon: Icons.restaurant_menu,
    categories: ['All', 'Life hacks'],
  ),
  _PromptItem(
    title: 'Workout Builder',
    description: 'Create personalized workout routines for your fitness goals and available equipment.',
    bgColor: Color(0xFFE8EAF6),
    icon: Icons.fitness_center,
    categories: ['All', 'Life hacks'],
  ),
  _PromptItem(
    title: 'Story Generator',
    description: 'Write short stories, plot outlines, or character backstories for creative projects.',
    bgColor: Color(0xFFFCE4EC),
    icon: Icons.auto_stories,
    categories: ['All', 'Be creative'],
  ),
  _PromptItem(
    title: 'Debug Helper',
    description: 'Paste error messages and stack traces to get clear explanations and fix suggestions.',
    bgColor: Color(0xFF263238),
    icon: Icons.bug_report_outlined,
    categories: ['All', 'Learn something'],
  ),
  _PromptItem(
    title: 'Travel Planner',
    description: 'Plan trips with itineraries, budget estimates, packing lists, and local tips.',
    bgColor: Color(0xFFE0F7FA),
    icon: Icons.flight_takeoff,
    categories: ['All', 'Life hacks'],
  ),
  _PromptItem(
    title: 'Quiz Master',
    description: 'Test your knowledge with AI-generated quizzes on any subject. Track your score.',
    bgColor: Color(0xFFFFECB3),
    icon: Icons.emoji_events_outlined,
    categories: ['All', 'Play a game'],
  ),
  _PromptItem(
    title: 'Resume Builder',
    description: 'Craft professional resumes and cover letters tailored to specific job descriptions.',
    bgColor: Color(0xFFE8E8E8),
    icon: Icons.description_outlined,
    categories: ['All', 'Life hacks'],
  ),
];

class PromptsScreen extends ConsumerStatefulWidget {
  const PromptsScreen({super.key});

  @override
  ConsumerState<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends ConsumerState<PromptsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Learn something', 'Life hacks', 'Play a game', 'Be creative'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgPrimary = isDark ? Colors.black : AppColors.bgPrimary;
    final textPrimary = isDark ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF666666) : const Color(0xFF999999);
    final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE4DFD8);

    final filtered = _selectedCategory == 'All'
        ? _inspirationPrompts
        : _inspirationPrompts.where((p) => p.categories.contains(_selectedCategory)).toList();

    return Scaffold(
      backgroundColor: bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  Row(
                    children: [
                      Text('Prompts',
                          style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: textPrimary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : const Color(0xFF1A1814),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('New prompt',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.black : Colors.white,
                              )),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tabs: Inspiration / Your prompts
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: textPrimary,
                    unselectedLabelColor: textMuted,
                    labelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
                    unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400),
                    indicatorColor: textPrimary,
                    indicatorWeight: 2,
                    dividerColor: borderColor,
                    tabs: const [
                      Tab(text: 'Inspiration'),
                      Tab(text: 'Your prompts'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Inspiration tab
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            // Category pills
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _categories.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final cat = _categories[index];
                                  final isActive = cat == _selectedCategory;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedCategory = cat),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? (isDark ? Colors.white : const Color(0xFF1A1814))
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: isActive ? null : Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        cat,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isActive
                                              ? (isDark ? Colors.black : Colors.white)
                                              : textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Grid of prompt cards
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossCount = constraints.maxWidth > 700
                                      ? 3
                                      : constraints.maxWidth > 450
                                          ? 2
                                          : 1;
                                  return GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) =>
                                        _buildPromptCard(filtered[index], isDark, textPrimary, textMuted, borderColor),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        // Your prompts tab
                        _buildYourPrompts(isDark, textPrimary, textMuted, borderColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(
      _PromptItem prompt, bool isDark, Color textPrimary, Color textMuted, Color borderColor) {
    final isDarkCard = prompt.bgColor.computeLuminance() < 0.4;

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview area with icon
            Expanded(
              flex: 3,
              child: Container(
                color: prompt.bgColor,
                child: Center(
                  child: Icon(
                    prompt.icon,
                    size: 48,
                    color: isDarkCard ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            // Title
            Container(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Text(
                prompt.title,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Description
            Container(
              color: isDark ? const Color(0xFF111111) : Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                prompt.description,
                style: GoogleFonts.dmSans(fontSize: 12, color: textMuted, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYourPrompts(bool isDark, Color textPrimary, Color textMuted, Color borderColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_outlined, size: 48, color: textMuted),
          const SizedBox(height: 16),
          Text(
            'No prompts yet',
            style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create prompts to reuse across your chats',
            style: GoogleFonts.dmSans(fontSize: 13, color: textMuted),
          ),
        ],
      ),
    );
  }
}
