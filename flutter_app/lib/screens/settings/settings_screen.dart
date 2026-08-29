import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/layout/responsive_wrapper.dart';
import '../../widgets/glow_card.dart';
import '../../widgets/staggered_entry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveWrapper.padding(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = ThemeNotifier.of(context);

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.headingSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimary
                : AppColorsLight.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondary
                : AppColorsLight.textSecondary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: padding, vertical: 20),
              children: [
                StaggeredEntry(
                  staggerDelay: const Duration(milliseconds: 80),
                  children: [
                    _buildAppearanceSection(
                        context, themeProvider, isDark),
                    const SizedBox(height: 20),
                    _buildNotificationsSection(context),
                    const SizedBox(height: 20),
                    _buildAboutSection(context),
                    const SizedBox(height: 32),
                    _buildFooter(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(
      BuildContext context, ThemeProvider provider, bool isDark) {
    final bgColor = isDark ? AppColors.card : AppColorsLight.card;
    final borderColor =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary =
        isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    final primaryGlow = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;

    return GlowCard(
      glowColor: primaryGlow,
      borderColor: borderColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGlow
                        : AppColorsLight.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    size: 18,
                    color:
                        isDark ? AppColors.primary : AppColorsLight.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Appearance', style: AppTheme.subtitleMedium.copyWith(color: textPrimary)),
              ],
            ),
            const SizedBox(height: 20),
            _buildThemeToggle(context, provider, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
      BuildContext context, ThemeProvider provider, bool isDark) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark ? AppColors.surface : AppColorsLight.surfaceElevated;
    final activeColor =
        isDark ? AppColors.primary : AppColorsLight.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _themeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Dark',
              isSelected: isDark,
              activeColor: activeColor,
              textPrimary: textPrimary,
              onTap: () => provider.setDark(),
            ),
          ),
          Expanded(
            child: _themeOption(
              icon: Icons.light_mode_rounded,
              label: 'Light',
              isSelected: !isDark,
              activeColor: activeColor,
              textPrimary: textPrimary,
              onTap: () => provider.setLight(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color activeColor,
    required Color textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: activeColor.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? activeColor : textPrimary.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
              child: Text(label),
            ),
            const SizedBox(width: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? activeColor : textPrimary.withOpacity(0.5),
              ),
              child: Icon(icon,
                  size: 18,
                  color: isSelected
                      ? activeColor
                      : textPrimary.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final glow2 = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;

    return GlowCard(
      glowColor: glow2,
      borderColor:
          isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGlow
                        : AppColorsLight.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_rounded,
                    size: 18,
                    color:
                        isDark ? AppColors.primary : AppColorsLight.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Notifications',
                    style: AppTheme.subtitleMedium.copyWith(color: textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Analysis complete alerts',
                  style: AppTheme.bodyLarge.copyWith(color: textSecondary)),
              subtitle: Text(
                  'Get notified when an investigation finishes',
                  style: AppTheme.bodySmall.copyWith(
                      color: (isDark
                              ? AppColors.textTertiary
                              : AppColorsLight.textTertiary))),
              value: _notifications,
              activeColor:
                  isDark ? AppColors.primary : AppColorsLight.primary,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                setState(() => _notifications = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textTertiary =
        isDark ? AppColors.textTertiary : AppColorsLight.textTertiary;

    final glow3 = isDark ? AppColors.primaryGlow : AppColorsLight.primaryGlow;

    return GlowCard(
      glowColor: glow3,
      borderColor:
          isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGlow
                        : AppColorsLight.primaryGlow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color:
                        isDark ? AppColors.primary : AppColorsLight.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('About',
                    style: AppTheme.subtitleMedium.copyWith(color: textPrimary)),
              ],
            ),
            const SizedBox(height: 16),
            _aboutRow('App', AppConstants.appName, textSecondary, textTertiary),
            const SizedBox(height: 10),
            _aboutRow(
                'Version', '1.0.0 (Prototype)', textSecondary, textTertiary),
            const SizedBox(height: 10),
            _aboutRow('Build', 'Review 1', textSecondary, textTertiary),
            const SizedBox(height: 10),
            _aboutRow(
                'Purpose', 'Hackathon UI/UX Demo', textSecondary, textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTheme.bodyMedium.copyWith(color: labelColor)),
        Text(value,
            style: AppTheme.bodyMedium
                .copyWith(color: valueColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Text(
          AppConstants.disclaimer,
          style: AppTheme.bodySmall.copyWith(
            color: textMuted,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
