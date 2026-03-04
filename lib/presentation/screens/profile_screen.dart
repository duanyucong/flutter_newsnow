import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user.dart';
import '../../providers/providers.dart';
import 'subscription_screen.dart';
import 'bookmarks_screen.dart';
import 'read_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final readHistory = ref.watch(readHistoryProvider);
    final theme = Theme.of(context);
    final user = User.defaultUser;

    final scrollController = ref.watch(scrollControllersProvider)[3];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            _buildHeader(context, user, theme),
            const SizedBox(height: 16),
            _buildStatsSection(context, bookmarks.length, readHistory.length, theme),
            const SizedBox(height: 16),
            _buildMenuSection(context, ref, bookmarks.length, theme),
            const SizedBox(height: 16),
            // _buildAboutSection(context, theme),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${user.id}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, int bookmarkCount, int historyCount, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.bookmark,
              count: bookmarkCount,
              label: '收藏',
              color: AppColors.warningColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookmarksScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.visibility,
              count: historyCount,
              label: '阅读',
              color: AppColors.accentColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReadHistoryScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref, int bookmarkCount, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            _buildMenuItem(
              context: context,
              icon: Icons.rss_feed,
              iconColor: Colors.orange,
              title: '订阅管理',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
              ),
            ),
            _buildDivider(theme),
            _buildMenuItem(
              context: context,
              icon: Icons.palette,
              iconColor: Colors.blue,
              title: '主题',
              trailing: _buildThemeChip(context, ref),
              onTap: () => _showThemeDialog(context, ref),
            ),
            _buildDivider(theme),
            _buildMenuItem(
              context: context,
              icon: Icons.info_outline,
              iconColor: Colors.grey,
              title: '关于',
              trailing: Text(
                'v${AppConstants.appVersion}',
                style: theme.textTheme.bodySmall,
              ),
              onTap: () => _showAboutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.textTheme.bodySmall?.color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 64,
      color: theme.dividerColor,
    );
  }

  Widget _buildThemeChip(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeModeProvider);
    
    String themeText = '跟随系统';
    if (currentMode == AppThemeMode.light) themeText = '浅色';
    if (currentMode == AppThemeMode.dark) themeText = '深色';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.dividerColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        themeText,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () => _showAboutDialog(context),
        child: const Text('退出登录'),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择主题',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(context, ref, '跟随系统', AppThemeMode.system, currentMode),
            _buildThemeOption(context, ref, '浅色模式', AppThemeMode.light, currentMode),
            _buildThemeOption(context, ref, '深色模式', AppThemeMode.dark, currentMode),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, String title, AppThemeMode mode, AppThemeMode currentMode) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(
        mode == AppThemeMode.system
            ? Icons.brightness_auto
            : mode == AppThemeMode.light
                ? Icons.light_mode
                : Icons.dark_mode,
        color: isSelected ? AppColors.accentColor : null,
      ),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.accentColor) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NewsNow v${AppConstants.appVersion}'),
            const SizedBox(height: 8),
            const Text('一个简洁的资讯聚合应用'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
