import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/kalvin_toast.dart';

class SettingsSheet extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool>? on3DToggle;
  final bool avatarEnabled;
  final ValueChanged<bool>? onAvatarToggle;

  const SettingsSheet({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.on3DToggle,
    this.avatarEnabled = true,
    this.onAvatarToggle,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();

  static void show(BuildContext context,
      {required bool isDarkMode,
      required VoidCallback onToggleTheme,
      ValueChanged<bool>? on3DToggle,
      bool avatarEnabled = true,
      ValueChanged<bool>? onAvatarToggle}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SettingsSheet(
        isDarkMode: isDarkMode,
        onToggleTheme: onToggleTheme,
        on3DToggle: on3DToggle,
        avatarEnabled: avatarEnabled,
        onAvatarToggle: onAvatarToggle,
      ),
    );
  }
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _is3DEnabled = false;
  bool _performanceMode = false;
  bool _audioEnabled = true;
  bool _notificationsEnabled = true;
  late bool _avatarEnabled;

  @override
  void initState() {
    super.initState();
    _avatarEnabled = widget.avatarEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey400.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded,
                      size: 22, color: AppColors.grey400),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark Mode',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: widget.isDarkMode,
                      onChanged: (_) {
                        widget.onToggleTheme();
                        KalvinToast.show(context,
                            message: widget.isDarkMode
                                ? '☀️ Light mode'
                                : '🌙 Dark mode',
                            type: ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _Tile(
                    icon: Icons.view_in_ar_rounded,
                    title: '3D Anaglyph',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _is3DEnabled,
                      onChanged: (val) {
                        setState(() => _is3DEnabled = val);
                        widget.on3DToggle?.call(val);
                        KalvinToast.show(context,
                            message: val
                                ? '🥽 Anaglyph 3D on'
                                : 'Standard mode',
                            type:
                                val ? ToastType.success : ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _Tile(
                    icon: Icons.volume_up_rounded,
                    title: 'Ambient Audio',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _audioEnabled,
                      onChanged: (val) {
                        setState(() => _audioEnabled = val);
                        KalvinToast.show(context,
                            message:
                                val ? '🔊 Audio on' : '🔇 Audio muted',
                            type: ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _Tile(
                    icon: Icons.speed_rounded,
                    title: 'Performance Mode',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _performanceMode,
                      onChanged: (val) {
                        setState(() => _performanceMode = val);
                        KalvinToast.show(context,
                            message: val
                                ? '⚡ Performance mode'
                                : '✨ Full quality',
                            type: ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _Tile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                        KalvinToast.show(context,
                            message: val
                                ? '🔔 Notifications on'
                                : '🔕 Notifications off',
                            type: ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  _Tile(
                    icon: Icons.smart_toy_rounded,
                    title: 'Enable Avatar',
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: _avatarEnabled,
                      onChanged: (val) {
                        setState(() => _avatarEnabled = val);
                        widget.onAvatarToggle?.call(val);
                        KalvinToast.show(context,
                            message: val
                                ? '✨ Kalvin is here!'
                                : '💤 Kalvin is resting',
                            type: ToastType.info);
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/avatars/leftideal.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kalvin v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final Widget trailing;

  const _Tile({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1A1C20),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
