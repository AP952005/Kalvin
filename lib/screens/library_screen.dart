import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/topic.dart';

class LibraryScreen extends StatelessWidget {
  final Function(Topic) onOpenTopic;

  const LibraryScreen({super.key, required this.onOpenTopic});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPadding + 16),

            // ── Title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1C20),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your saved lessons and scenes',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey400,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grey100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search lessons...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Categories ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Categories',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1C20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    isActive: true,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Science',
                    isActive: false,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Geography',
                    isActive: false,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Biology',
                    isActive: false,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Downloaded Scenes ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Downloaded Scenes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1C20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...Topic.allTopics.map((topic) {
              return _LibraryItem(
                topic: topic,
                isDark: isDark,
                onTap: () => onOpenTopic(topic),
              );
            }),

            const SizedBox(height: 24),

            // ── Bookmarks (empty state) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Bookmarks',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1C20),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 40,
                      color: AppColors.grey400,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No bookmarks yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save lessons to access them here',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;

  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive ? AppColors.primaryGradient : null,
        color: isActive
            ? null
            : (isDark ? AppColors.darkCard : AppColors.grey100),
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? null
            : Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? Colors.white
              : (isDark ? AppColors.grey300 : AppColors.grey600),
        ),
      ),
    );
  }
}

class _LibraryItem extends StatelessWidget {
  final Topic topic;
  final bool isDark;
  final VoidCallback onTap;

  const _LibraryItem({
    required this.topic,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: topic.gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(topic.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1A1C20),
                    ),
                  ),
                  Text(
                    'Downloaded · Ready',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_outline_rounded,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
