import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化屏幕旋转设置
  final container = ProviderContainer();
  await container.read(screenRotationProvider.notifier).initialized;
  
  runApp(
    ProviderScope(
      parent: container,
      child: const NewsNowApp(),
    ),
  );
}

class NewsNowApp extends ConsumerWidget {
  const NewsNowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // 根据主题模式确定系统UI样式
    final isDark = themeMode == AppThemeMode.dark ||
        (themeMode == AppThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    // 设置系统导航条颜色跟随主题
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    
    return MaterialApp(
      title: 'NewsNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.light 
          ? ThemeMode.light 
          : themeMode == AppThemeMode.dark 
              ? ThemeMode.dark 
              : ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
