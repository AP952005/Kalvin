import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/session_model.dart';
import '../models/topic.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<Topic> onOpenTopic;

  const HistoryScreen({super.key, required this.onOpenTopic});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Demo sessions (will be persisted later)
  final List<SessionModel> _sessions = [
    SessionModel(
      id: '1',
      title: 'Solar System',
      scene: 'solar_system',
      timelineStep: 2,
      messages: [
        ChatMessage(
          text:
              'Welcome to the Solar System experience! I\'ll guide you through this topic step by step.',
          isUser: false,
        ),
        ChatMessage(
          text: 'What is the diameter of the Sun?',
          isUser: true,
        ),
        ChatMessage(
          text:
              'The Sun has a diameter of approximately 1.39 million km — about 109 times the diameter of Earth!',
          isUser: false,
        ),
      ],
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SessionModel(
      id: '2',
      title: 'Volcanoes',
      scene: 'volcano',
      timelineStep: 1,
      isBookmarked: true,
      messages: [
        ChatMessage(
          text: 'Welcome to the Volcano experience!',
          isUser: false,
        ),
        ChatMessage(
          text: 'How hot is lava?',
          isUser: true,
        ),
        ChatMessage(
          text:
              'Lava temperatures range from 700°C to 1,300°C depending on its composition.',
          isUser: false,
        ),
      ],
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SessionModel(
      id: '3',
      title: 'Water Cycle',
      scene: 'water_cycle',
      timelineStep: 0,
      messages: [
        ChatMessage(
          text: 'Welcome to the Water Cycle experience!',
          isUser: false,
        ),
      ],
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  String _filter = 'all'; // all, bookmarked

  List<SessionModel> get _filtered {
    if (_filter == 'bookmarked') {
      return _sessions.where((s) => s.isBookmarked).toList();
    }
    return _sessions;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPadding + 12),

          // ── Title ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'History',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1C20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${_sessions.length} learning sessions',
              style: TextStyle(fontSize: 13, color: AppColors.grey400),
            ),
          ),

          const SizedBox(height: 16),

          // ── Filter chips ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isActive: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Bookmarked',
                  isActive: _filter == 'bookmarked',
                  onTap: () => setState(() => _filter = 'bookmarked'),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Sessions list ──
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      return _SessionTile(
                        session: _filtered[index],
                        isDark: isDark,
                        onTap: () => _openSession(_filtered[index]),
                        onBookmark: () => _toggleBookmark(_filtered[index]),
                        onDelete: () => _deleteSession(_filtered[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_outline_rounded,
              size: 48, color: AppColors.grey400.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No bookmarked sessions',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
    );
  }

  void _openSession(SessionModel session) {
    // Find matching topic
    final topic = Topic.allTopics.firstWhere(
      (t) => t.scene == session.scene,
      orElse: () => Topic.allTopics[0],
    );
    widget.onOpenTopic(topic);
  }

  void _toggleBookmark(SessionModel session) {
    setState(() {
      session.isBookmarked = !session.isBookmarked;
    });
  }

  void _deleteSession(SessionModel session) {
    setState(() {
      _sessions.remove(session);
    });
  }
}

// ── Filter chip ──
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCard : AppColors.grey100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive
                ? AppColors.primaryBlue
                : (isDark ? AppColors.grey300 : AppColors.grey600),
          ),
        ),
      ),
    );
  }
}

// ── Session tile ──
class _SessionTile extends StatelessWidget {
  final SessionModel session;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isDark,
    required this.onTap,
    required this.onBookmark,
    required this.onDelete,
  });

  IconData get _sceneIcon {
    switch (session.scene) {
      case 'volcano':
        return Icons.terrain;
      case 'water_cycle':
        return Icons.water_drop;
      case 'solar_system':
      default:
        return Icons.public;
    }
  }

  Color get _sceneColor {
    switch (session.scene) {
      case 'volcano':
        return const Color(0xFFFF6B35);
      case 'water_cycle':
        return const Color(0xFF00BCD4);
      case 'solar_system':
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
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
            // Scene icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _sceneColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_sceneIcon, size: 20, color: _sceneColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1C20),
                          ),
                        ),
                      ),
                      Text(
                        session.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    session.previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Progress + actions
                  Row(
                    children: [
                      // Progress dots
                      ...List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= session.timelineStep
                                ? _sceneColor
                                : AppColors.grey400.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                      const Spacer(),
                      GestureDetector(
                        onTap: onBookmark,
                        child: Icon(
                          session.isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          size: 18,
                          color: session.isBookmarked
                              ? AppColors.primaryOrange
                              : AppColors.grey400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.grey400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
