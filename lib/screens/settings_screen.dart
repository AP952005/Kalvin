import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/kalvin_toast.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<bool>? on3DToggle;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.on3DToggle,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _is3DEnabled = false;
  bool _performanceMode = false;

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
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1C20),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Appearance ──
            _SectionTitle(title: 'Appearance', isDark: isDark),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: widget.isDarkMode ? 'Enabled' : 'Disabled',
              isDark: isDark,
              trailing: Switch.adaptive(
                value: widget.isDarkMode,
                onChanged: (_) {
                  widget.onToggleTheme();
                  KalvinToast.show(
                    context,
                    message: widget.isDarkMode
                        ? '☀️ Light mode enabled'
                        : '🌙 Dark mode enabled',
                    type: ToastType.info,
                  );
                },
                activeColor: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            // ── Rendering ──
            _SectionTitle(title: 'Rendering', isDark: isDark),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.view_in_ar_rounded,
              title: '3D Anaglyph Mode',
              subtitle: _is3DEnabled
                  ? 'Red-cyan stereoscopic enabled'
                  : 'Standard rendering',
              isDark: isDark,
              trailing: Switch.adaptive(
                value: _is3DEnabled,
                onChanged: (val) {
                  setState(() => _is3DEnabled = val);
                  widget.on3DToggle?.call(val);
                  KalvinToast.show(
                    context,
                    message: val
                        ? '🥽 Anaglyph 3D enabled — grab your glasses!'
                        : 'Standard rendering mode',
                    type: val ? ToastType.success : ToastType.info,
                  );
                },
                activeColor: AppColors.primaryBlue,
              ),
            ),
            _SettingsTile(
              icon: Icons.speed_rounded,
              title: 'Performance Mode',
              subtitle: _performanceMode
                  ? 'Lower quality, smoother rendering'
                  : 'Full quality rendering',
              isDark: isDark,
              trailing: Switch.adaptive(
                value: _performanceMode,
                onChanged: (val) {
                  setState(() => _performanceMode = val);
                  KalvinToast.show(
                    context,
                    message: val
                        ? '⚡ Performance mode enabled'
                        : '✨ Full quality rendering',
                    type: ToastType.info,
                  );
                },
                activeColor: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 24),

            // ── General ──
            _SectionTitle(title: 'General', isDark: isDark),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'English',
              isDark: isDark,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.grey400,
              ),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About Kalvin',
              subtitle: 'Version 1.0.0 MVP',
              isDark: isDark,
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.grey400,
              ),
            ),

            const SizedBox(height: 32),

            // ── App info ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Kalvin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1A1C20),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI-Powered Interactive Learning',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.grey400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.grey100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1C20),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
