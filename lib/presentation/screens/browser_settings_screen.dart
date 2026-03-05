import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class BrowserSettingsScreen extends ConsumerWidget {
  const BrowserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(webViewSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览设置'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('浏览选项', theme),
          _buildSwitchTile(
            context: context,
            title: 'JavaScript',
            subtitle: '允许网页执行JavaScript脚本',
            icon: Icons.code,
            iconColor: Colors.blue,
            value: settings.javascriptEnabled,
            onChanged: (value) {
              ref.read(webViewSettingsProvider.notifier).setJavascriptEnabled(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            title: '暗黑模式',
            subtitle: '为网页应用深色主题',
            icon: Icons.dark_mode,
            iconColor: Colors.purple,
            value: settings.darkModeEnabled,
            onChanged: (value) {
              ref.read(webViewSettingsProvider.notifier).setDarkModeEnabled(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            title: '广告拦截',
            subtitle: '拦截网页中的广告内容',
            icon: Icons.block,
            iconColor: Colors.red,
            value: settings.adBlockEnabled,
            onChanged: (value) {
              ref.read(webViewSettingsProvider.notifier).setAdBlockEnabled(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            title: '无图模式',
            subtitle: '不加载网页中的图片',
            icon: Icons.image_not_supported,
            iconColor: Colors.orange,
            value: settings.noImageMode,
            onChanged: (value) {
              ref.read(webViewSettingsProvider.notifier).setNoImageMode(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            title: '桌面版',
            subtitle: '使用桌面版User-Agent',
            icon: Icons.desktop_windows,
            iconColor: Colors.teal,
            value: settings.desktopMode,
            onChanged: (value) {
              ref.read(webViewSettingsProvider.notifier).setDesktopMode(value);
            },
          ),
          _buildSectionHeader('显示', theme),
          _buildTextSizeTile(context, ref, settings.textSize, theme),
          _buildSectionHeader('关于', theme),
          _buildInfoTile(
            context: context,
            title: '版本',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            iconColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildTextSizeTile(BuildContext context, WidgetRef ref, int textSize, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.text_fields, color: Colors.green, size: 18),
        ),
        title: const Text('字体大小'),
        subtitle: Row(
          children: [
            const Text('小'),
            Expanded(
              child: Slider(
                value: textSize.toDouble(),
                min: 12,
                max: 24,
                divisions: 6,
                label: '${textSize}px',
                onChanged: (value) {
                  ref.read(webViewSettingsProvider.notifier).setTextSize(value.toInt());
                },
              ),
            ),
            const Text('大'),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
