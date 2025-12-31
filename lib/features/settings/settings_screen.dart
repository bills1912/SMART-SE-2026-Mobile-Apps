import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/chat_provider.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark 
              ? AppColors.darkBackgroundGradient 
              : AppColors.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context, isDark),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Appearance Section
                      _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
                      const SizedBox(height: 12),
                      _buildAppearanceSection(context, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // Data & Storage Section
                      _buildSectionHeader(context, 'Data & Storage', Icons.storage_outlined),
                      const SizedBox(height: 12),
                      _buildDataSection(context, isDark),
                      
                      const SizedBox(height: 24),
                      
                      // About Section
                      _buildSectionHeader(context, 'About', Icons.info_outline),
                      const SizedBox(height: 12),
                      _buildAboutSection(context, isDark),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryOrange,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildAppearanceSection(BuildContext context, bool isDark) {
    final themeProvider = context.watch<ThemeProvider>();

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildSettingItem(
            context: context,
            icon: Icons.light_mode,
            title: 'Light Mode',
            trailing: Radio<ThemeModeType>(
              value: ThemeModeType.light,
              groupValue: themeProvider.themeModeType,
              onChanged: (_) => themeProvider.setThemeMode(ThemeModeType.light),
              activeColor: AppColors.primaryOrange,
            ),
            onTap: () => themeProvider.setThemeMode(ThemeModeType.light),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Radio<ThemeModeType>(
              value: ThemeModeType.dark,
              groupValue: themeProvider.themeModeType,
              onChanged: (_) => themeProvider.setThemeMode(ThemeModeType.dark),
              activeColor: AppColors.primaryOrange,
            ),
            onTap: () => themeProvider.setThemeMode(ThemeModeType.dark),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.auto_mode,
            title: 'System Default',
            trailing: Radio<ThemeModeType>(
              value: ThemeModeType.system,
              groupValue: themeProvider.themeModeType,
              onChanged: (_) => themeProvider.setThemeMode(ThemeModeType.system),
              activeColor: AppColors.primaryOrange,
            ),
            onTap: () => themeProvider.setThemeMode(ThemeModeType.system),
            isDark: isDark,
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildDataSection(BuildContext context, bool isDark) {
    final chatProvider = context.watch<ChatProvider>();

    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildSettingItem(
            context: context,
            icon: Icons.download,
            title: 'Export All Chats',
            subtitle: 'Download your conversation history',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () => chatProvider.exportAllChats(),
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.delete_outline,
            title: 'Clear Chat History',
            subtitle: '${chatProvider.sessions.length} conversations',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () => _showClearHistoryDialog(context, isDark, chatProvider),
            isDark: isDark,
            isDestructive: true,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.cached,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () => _showClearCacheDialog(context, isDark),
            isDark: isDark,
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAboutSection(BuildContext context, bool isDark) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          _buildSettingItem(
            context: context,
            icon: Icons.info_outline,
            title: 'Version',
            trailing: Text(
              '1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            onTap: () {},
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () {
              // TODO: Open Terms of Service
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () {
              // TODO: Open Privacy Policy
            },
            isDark: isDark,
          ),
          _buildDivider(isDark),
          _buildSettingItem(
            context: context,
            icon: Icons.code,
            title: 'Open Source Licenses',
            trailing: Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
            ),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'SMART SE2026',
                applicationVersion: '1.0.0',
              );
            },
            isDark: isDark,
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? AppColors.error : AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDestructive 
                            ? AppColors.error
                            : (isDark 
                                ? AppColors.darkTextPrimary 
                                : AppColors.lightTextPrimary),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark 
                              ? AppColors.darkTextTertiary 
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 66,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
    );
  }

  void _showClearHistoryDialog(BuildContext context, bool isDark, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Clear Chat History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all ${chatProvider.sessions.length} conversations. This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.deleteAllSessions();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Chat history cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Cache',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will clear temporary files and cached data. Your chat history will not be affected.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cache cleared successfully'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
