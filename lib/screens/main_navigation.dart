import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/topic.dart';
import '../services/tts_service.dart';
import '../widgets/kalvin_avatar.dart';
import '../widgets/kalvin_toast.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'history_screen.dart';
import 'settings_sheet.dart';

class MainNavigation extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainNavigation({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<LearnScreenState> _learnKey = GlobalKey<LearnScreenState>();
  final GlobalKey<KalvinAvatarState> _avatarKey =
      GlobalKey<KalvinAvatarState>();

  bool _avatarVisible = true;
  bool _avatarEverDismissed = false;
  final KalvinTTS _tts = KalvinTTS();
  bool _greetingPlayed = false; // prevent overlapping greetings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    super.dispose();
  }

  /// App lifecycle — greet on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_greetingPlayed) {
      _playGreeting();
    }
  }

  Future<void> _initServices() async {
    await _tts.init();

    // Load avatar preference
    final avatarEnabled = await KalvinTTS.isAvatarEnabled();
    if (mounted) {
      setState(() => _avatarVisible = avatarEnabled);
    }

    // Wait for UI to fully settle before greeting
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _playGreeting();
    }
  }

  Future<void> _playGreeting() async {
    if (_greetingPlayed || !mounted || !_avatarVisible) return;
    _greetingPlayed = true;

    // Check if first launch
    final isFirst = await KalvinTTS.isFirstLaunch();
    final greeting = isFirst
        ? "Hi, I am Kalvin, your learning friend. How can I help you today?"
        : "Welcome back! What shall we explore today?";

    if (!mounted) return;

    _avatarKey.currentState?.setSpeaking(true);
    await _tts.speak(greeting);

    // Wait for speech to finish (approximate)
    await Future.delayed(Duration(seconds: isFirst ? 4 : 3));

    if (mounted) {
      _avatarKey.currentState?.setSpeaking(false);
    }

    if (isFirst) {
      await KalvinTTS.markFirstLaunchDone();
    }

    // Allow greeting again after 60 seconds (for app resume)
    Future.delayed(const Duration(seconds: 60), () {
      _greetingPlayed = false;
    });
  }

  void _onTabTap(int index) {
    // Double-tap on current tab → restore avatar if dismissed
    if (index == _currentIndex && _avatarEverDismissed && !_avatarVisible) {
      _restoreAvatar();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _openTopicInLearn(Topic topic) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _learnKey.currentState?.loadTopic(topic);
    });

    // TTS announcement
    _avatarKey.currentState?.setSpeaking(true);
    _tts.speak("Opening ${topic.title} lesson.");
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _avatarKey.currentState?.setSpeaking(false);
    });
  }

  void _on3DToggle(bool enabled) {
    _learnKey.currentState?.runJS("toggle3DMode($enabled)");
  }

  void _openSettings() {
    SettingsSheet.show(
      context,
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      on3DToggle: _on3DToggle,
      avatarEnabled: _avatarVisible,
      onAvatarToggle: (enabled) {
        setState(() => _avatarVisible = enabled);
        KalvinTTS.setAvatarEnabled(enabled);
      },
    );
  }

  void _onAvatarTap() {
    _avatarKey.currentState?.setSpeaking(true);
    _tts.speak("Let's explore something amazing together!");
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _avatarKey.currentState?.setSpeaking(false);
    });
  }

  void _onAvatarDismiss() {
    setState(() {
      _avatarVisible = false;
      _avatarEverDismissed = true;
    });
    KalvinTTS.setAvatarEnabled(false);
    if (mounted) {
      KalvinToast.show(
        context,
        message: 'Kalvin is resting. Double-tap a tab to bring me back!',
        type: ToastType.info,
      );
    }
  }

  void _restoreAvatar() {
    setState(() => _avatarVisible = true);
    KalvinTTS.setAvatarEnabled(true);

    // Wait for widget to rebuild before animating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _avatarKey.currentState?.setSpeaking(true);
      _tts.speak("I'm back! Ready to learn?");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _avatarKey.currentState?.setSpeaking(false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Screen stack ──
          IndexedStack(
            index: _currentIndex,
            children: [
              HomeScreen(
                onOpenTopic: _openTopicInLearn,
                onNewChat: () {
                  setState(() => _currentIndex = 1);
                },
              ),
              LearnScreen(key: _learnKey, activeTopic: Topic.allTopics[0]),
              HistoryScreen(onOpenTopic: _openTopicInLearn),
            ],
          ),

          // ── Settings button (top-right, on Home + History only) ──
          if (_currentIndex != 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: _openSettings,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    size: 18,
                    color: isDark ? AppColors.grey300 : AppColors.grey600,
                  ),
                ),
              ),
            ),

          // ── Global Floating Avatar (ABOVE everything) ──
          KalvinAvatar(
            key: _avatarKey,
            visible: _avatarVisible,
            onTap: _onAvatarTap,
            onDismiss: _onAvatarDismiss,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onTabTap(0),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: Icons.science_rounded,
                  label: 'Learn',
                  isActive: _currentIndex == 1,
                  onTap: () => _onTabTap(1),
                  isDark: isDark,
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isActive: _currentIndex == 2,
                  onTap: () => _onTabTap(2),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.grey500 : AppColors.grey400),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primaryBlue
                    : (isDark ? AppColors.grey500 : AppColors.grey400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
