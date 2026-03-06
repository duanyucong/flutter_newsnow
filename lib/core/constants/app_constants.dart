class AppConstants {
  static const String appName = 'NewsNow';
  static const String appVersion = '26.3.6';
  
  // API Base URL (mock for now)
  static const String baseUrl = 'https://api.newsnow.example.com';
  
  // Storage Keys
  static const String themeKey = 'theme';
  static const String bookmarksKey = 'bookmarks';
  static const String userKey = 'user';
  static const String subscriptionsKey = 'subscriptions';
  static const String readHistoryKey = 'read_history';
  static const String screenRotationKey = 'screen_rotation';
  static const String webviewSettingsKey = 'webview_settings';
  
  // Max read history count
  static const int maxReadHistoryCount = 300;
  
  // News Sources
  static const List<String> newsSources = [
    'all',
    'tech',
    'finance', 
    'entertainment',
    'sports',
  ];
  
  // Follow Sources
  static const List<String> followSources = [
    'zhihu',
    'weibo',
    'fenghuang',
    'baidu',
  ];
}
