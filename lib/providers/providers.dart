import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pinyin/pinyin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/models/news_item.dart';
import '../data/models/news.dart';
import '../data/models/sources.dart';
import '../data/datasources/api_client.dart';
import '../data/datasources/news_api_service.dart';
import '../data/repositories/news_repository.dart';

enum AppThemeMode { light, dark, system }

enum ScreenRotationMode { followSystem, portrait, landscape }

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

final screenRotationProvider = StateNotifierProvider<ScreenRotationNotifier, ScreenRotationMode>((ref) {
  return ScreenRotationNotifier();
});

class WebViewSettings {
  final bool javascriptEnabled;
  final bool darkModeEnabled;
  final bool adBlockEnabled;
  final bool noImageMode;
  final bool desktopMode;
  final int textSize;

  const WebViewSettings({
    this.javascriptEnabled = true,
    this.darkModeEnabled = false,
    this.adBlockEnabled = true,
    this.noImageMode = false,
    this.desktopMode = false,
    this.textSize = 16,
  });

  WebViewSettings copyWith({
    bool? javascriptEnabled,
    bool? darkModeEnabled,
    bool? adBlockEnabled,
    bool? noImageMode,
    bool? desktopMode,
    int? textSize,
  }) {
    return WebViewSettings(
      javascriptEnabled: javascriptEnabled ?? this.javascriptEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      adBlockEnabled: adBlockEnabled ?? this.adBlockEnabled,
      noImageMode: noImageMode ?? this.noImageMode,
      desktopMode: desktopMode ?? this.desktopMode,
      textSize: textSize ?? this.textSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'javascriptEnabled': javascriptEnabled,
      'darkModeEnabled': darkModeEnabled,
      'adBlockEnabled': adBlockEnabled,
      'noImageMode': noImageMode,
      'desktopMode': desktopMode,
      'textSize': textSize,
    };
  }

  factory WebViewSettings.fromJson(Map<String, dynamic> json) {
    return WebViewSettings(
      javascriptEnabled: json['javascriptEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      adBlockEnabled: json['adBlockEnabled'] ?? true,
      noImageMode: json['noImageMode'] ?? false,
      desktopMode: json['desktopMode'] ?? false,
      textSize: json['textSize'] ?? 16,
    );
  }
}

final webViewSettingsProvider = StateNotifierProvider<WebViewSettingsNotifier, WebViewSettings>((ref) {
  return WebViewSettingsNotifier();
});

class WebViewSettingsNotifier extends StateNotifier<WebViewSettings> {
  WebViewSettingsNotifier() : super(const WebViewSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(AppConstants.webviewSettingsKey);
    if (settingsJson != null) {
      try {
        final map = json.decode(settingsJson) as Map<String, dynamic>;
        state = WebViewSettings.fromJson(map);
      } catch (e) {
        debugPrint('Failed to load webview settings: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = json.encode(state.toJson());
    await prefs.setString(AppConstants.webviewSettingsKey, settingsJson);
  }

  void setJavascriptEnabled(bool value) {
    state = state.copyWith(javascriptEnabled: value);
    _saveSettings();
  }

  void setDarkModeEnabled(bool value) {
    state = state.copyWith(darkModeEnabled: value);
    _saveSettings();
  }

  void setAdBlockEnabled(bool value) {
    state = state.copyWith(adBlockEnabled: value);
    _saveSettings();
  }

  void setNoImageMode(bool value) {
    state = state.copyWith(noImageMode: value);
    _saveSettings();
  }

  void setDesktopMode(bool value) {
    state = state.copyWith(desktopMode: value);
    _saveSettings();
  }

  void setTextSize(int value) {
    state = state.copyWith(textSize: value);
    _saveSettings();
  }
}

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(AppConstants.themeKey) ?? 'system';
    state = _parseThemeMode(themeMode);
  }

  AppThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      default:
        return AppThemeMode.system;
    }
  }

  String _themeModeToString(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeKey, _themeModeToString(mode));
  }

  bool get isDark => state == AppThemeMode.dark;
}

class ScreenRotationNotifier extends StateNotifier<ScreenRotationMode> {
  late Future<void> _initFuture;
  
  ScreenRotationNotifier() : super(ScreenRotationMode.followSystem) {
    _initFuture = _loadRotation();
  }
  
  Future<void> get initialized => _initFuture;

  Future<void> _loadRotation() async {
    final prefs = await SharedPreferences.getInstance();
    final rotationMode = prefs.getString(AppConstants.screenRotationKey) ?? 'followSystem';
    state = _parseRotationMode(rotationMode);
    _applyRotation();
  }

  ScreenRotationMode _parseRotationMode(String value) {
    switch (value) {
      case 'portrait':
        return ScreenRotationMode.portrait;
      case 'landscape':
        return ScreenRotationMode.landscape;
      default:
        return ScreenRotationMode.followSystem;
    }
  }

  String _rotationModeToString(ScreenRotationMode mode) {
    switch (mode) {
      case ScreenRotationMode.followSystem:
        return 'followSystem';
      case ScreenRotationMode.portrait:
        return 'portrait';
      case ScreenRotationMode.landscape:
        return 'landscape';
    }
  }

  Future<void> setRotationMode(ScreenRotationMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.screenRotationKey, _rotationModeToString(mode));
    _applyRotation();
  }

  void _applyRotation() {
    switch (state) {
      case ScreenRotationMode.followSystem:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case ScreenRotationMode.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case ScreenRotationMode.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final newsApiServiceProvider = Provider<NewsApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NewsApiService(apiClient.dio);
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final apiService = ref.watch(newsApiServiceProvider);
  return NewsRepository(apiService);
});

final hottestSourcesProvider = Provider<List<String>>((ref) {
  final followSources = ref.watch(followSourcesProvider);
  if (followSources.isEmpty) {
    return Sources.hottestSources.take(8).toList();
  }
  final subscribedHottest = followSources
      .where((s) => s.type == 'hottest' && s.isSubscribed)
      .map((s) => s.id)
      .toList();
  if (subscribedHottest.isEmpty) {
    return Sources.hottestSources.take(8).toList();
  }
  return subscribedHottest;
});

final realtimeSourcesProvider = Provider<List<String>>((ref) {
  final followSources = ref.watch(followSourcesProvider);
  if (followSources.isEmpty) {
    return Sources.realtimeSources.take(5).toList();
  }
  final subscribedRealtime = followSources
      .where((s) => s.type == 'realtime' && s.isSubscribed)
      .map((s) => s.id)
      .toList();
  if (subscribedRealtime.isEmpty) {
    return Sources.realtimeSources.take(5).toList();
  }
  return subscribedRealtime;
});

News _convertToNews(NewsItem item, String sourceId) {
  final source = Sources.getSource(sourceId);
  final dateValue = item.extra?.date;
  String timeStr = '';
  int timestamp = 0;
  
  if (dateValue is int) {
    timestamp = dateValue;
    timeStr = _formatRelativeTime(dateValue);
  } else if (dateValue is String) {
    try {
      timestamp = int.parse(dateValue);
      timeStr = _formatRelativeTime(timestamp);
    } catch (_) {
      timeStr = dateValue;
    }
  } else {
    timeStr = item.extra?.date?.toString() ?? '';
  }
  
  return News(
    id: item.newsId,
    title: item.title,
    description: item.hoverText ?? item.title,
    content: item.hoverText ?? item.title,
    source: source?.name ?? sourceId,
    sourceId: sourceId,
    time: timeStr,
    timestamp: timestamp,
    url: item.displayUrl,
    likes: 0,
    comments: 0,
    category: source?.column ?? 'hot',
  );
}

String _formatRelativeTime(int timestamp) {
  if (timestamp == 0) return '';
  
  final nowSeconds = DateTime.now().millisecondsSinceEpoch;
  final diff = nowSeconds - timestamp;
  
  if (diff < 60000) {
    return '刚刚';
  } else if (diff < 3600000) {
    return '${diff ~/ 60000}分钟前';
  } else if (diff < 86400000) {
    return '${diff ~/ 3600000}小时前';
  } else if (diff < 604800000) {
    return '${diff ~/ 86400000}天前';
  } else {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MM-dd').format(dateTime);
  }
}

List<News> _interleaveBySource(List<SourceResponse> responses) {
  if (responses.isEmpty) return [];
  
  final result = <News>[];
  final maxItems = responses.map((r) => r.items.length).reduce((a, b) => a > b ? a : b);
  
  for (int i = 0; i < maxItems; i++) {
    for (final response in responses) {
      if (i < response.items.length) {
        result.add(_convertToNews(response.items[i], response.id));
      }
    }
  }
  
  return _sortNews(result);
}

List<News> _sortNews(List<News> news) {
  final sorted = List<News>.from(news);
  sorted.sort((a, b) {
    final timestampCompare = b.timestamp.compareTo(a.timestamp);
    if (timestampCompare != 0) return timestampCompare;
    
    final aFirstLetter = _getFirstLetter(a.title);
    final bFirstLetter = _getFirstLetter(b.title);
    return aFirstLetter.compareTo(bFirstLetter);
  });
  return sorted;
}

String _getFirstLetter(String title) {
  if (title.isEmpty) return '';
  final pinyin = PinyinHelper.getFirstWordPinyin(title);
  if (pinyin.isEmpty || !pinyin.contains(RegExp(r'[a-zA-Z]'))) {
    return title[0].toUpperCase();
  }
  return pinyin[0].toUpperCase();
}

final hotNewsProvider = StateNotifierProvider<HotNewsNotifier, AsyncValue<List<News>>>((ref) {
  final notifier = HotNewsNotifier(ref);
  ref.listen(hottestSourcesProvider, (_, __) {
    notifier.loadNews();
  });
  ref.listen(followSourcesProvider, (_, __) {
    notifier.loadNews();
  });
  return notifier;
});

class HotNewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  
  HotNewsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadNews();
  }

  Future<void> loadNews() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(newsRepositoryProvider);
      final sources = ref.read(hottestSourcesProvider);
      
      final responses = await repository.getEntireSources(sources);
      final interleavedNews = _interleaveBySource(responses);
      
      state = AsyncValue.data(interleavedNews);
      
      final followSources = ref.read(followSourcesProvider);
      if (followSources.isNotEmpty) {
        final subscribedSources = followSources
            .where((s) => s.type == 'hottest' && s.isSubscribed)
            .map((s) => s.id)
            .toList();
        if (subscribedSources.isNotEmpty) {
          final newResponses = await repository.getEntireSources(subscribedSources);
          final newNews = _interleaveBySource(newResponses);
          state = AsyncValue.data(newNews);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadNews();
  }
}

final liveNewsProvider = StateNotifierProvider<LiveNewsNotifier, AsyncValue<List<News>>>((ref) {
  final notifier = LiveNewsNotifier(ref);
  ref.listen(realtimeSourcesProvider, (_, __) {
    notifier.loadNews();
  });
  ref.listen(followSourcesProvider, (_, __) {
    notifier.loadNews();
  });
  return notifier;
});

class LiveNewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  
  LiveNewsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadNews();
  }

  Future<void> loadNews() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(newsRepositoryProvider);
      final sources = ref.read(realtimeSourcesProvider);
      
      final responses = await repository.getEntireSources(sources);
      final interleavedNews = _interleaveBySource(responses);
      
      state = AsyncValue.data(interleavedNews);
      
      final followSources = ref.read(followSourcesProvider);
      if (followSources.isNotEmpty) {
        final subscribedSources = followSources
            .where((s) => s.type == 'realtime' && s.isSubscribed)
            .map((s) => s.id)
            .toList();
        if (subscribedSources.isNotEmpty) {
          final newResponses = await repository.getEntireSources(subscribedSources);
          final newNews = _interleaveBySource(newResponses);
          state = AsyncValue.data(newNews);
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadNews();
  }
}

final followSourceProvider = StateProvider<String>((ref) {
  final followSources = ref.watch(followSourcesProvider);
  if (followSources.isEmpty) {
    return 'zhihu';
  }
  final firstSubscribed = followSources.firstWhere(
    (s) => s.isSubscribed,
    orElse: () => followSources.first,
  );
  return firstSubscribed.id;
});

final followNewsProvider = StateNotifierProvider<FollowNewsNotifier, AsyncValue<List<News>>>((ref) {
  final sourceId = ref.watch(followSourceProvider);
  return FollowNewsNotifier(ref, sourceId);
});

class FollowNewsNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  final String sourceId;
  
  FollowNewsNotifier(this.ref, this.sourceId) : super(const AsyncValue.loading()) {
    loadNews();
  }

  Future<void> loadNews() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(newsRepositoryProvider);
      final response = await repository.getSource(sourceId, latest: true);
      
      final news = response.items.map((item) => _convertToNews(item, response.id)).toList();
      state = AsyncValue.data(news);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadNews();
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<News>>((ref) {
  return BookmarksNotifier();
});

class BookmarksNotifier extends StateNotifier<List<News>> {
  BookmarksNotifier() : super([]) {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(AppConstants.bookmarksKey) ?? [];
    final bookmarks = bookmarksJson
        .map((jsonStr) {
          try {
            final map = json.decode(jsonStr) as Map<String, dynamic>;
            return News(
              id: map['id'] ?? '',
              title: map['title'] ?? '',
              description: map['description'] ?? '',
              content: map['content'] ?? '',
              source: map['source'] ?? '',
              sourceId: map['sourceId'] ?? '',
              time: map['time'] ?? '',
              timestamp: map['timestamp'] ?? 0,
              imageUrl: map['imageUrl'],
              likes: map['likes'] ?? 0,
              comments: map['comments'] ?? 0,
              category: map['category'] ?? 'hot',
              url: map['url'],
            );
          } catch (e) {
            return null;
          }
        })
        .whereType<News>()
        .where((news) => news.id.isNotEmpty)
        .toList();
    state = bookmarks;
  }

  Future<void> toggleBookmark(News news) async {
    if (news.id.isEmpty) return;
    
    final existingIndex = state.indexWhere((n) => n.id == news.id);
    if (existingIndex != -1) {
      state = [...state]..removeAt(existingIndex);
    } else {
      state = [news, ...state];
    }
    
    await _saveBookmarks();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = state.map((news) {
      return json.encode({
        'id': news.id,
        'title': news.title,
        'description': news.description,
        'content': news.content,
        'source': news.source,
        'sourceId': news.sourceId,
        'time': news.time,
        'timestamp': news.timestamp,
        'imageUrl': news.imageUrl,
        'likes': news.likes,
        'comments': news.comments,
        'category': news.category,
        'url': news.url,
      });
    }).toList();
    await prefs.setStringList(AppConstants.bookmarksKey, bookmarksJson);
  }

  bool isBookmarked(String newsId) {
    return state.any((news) => news.id == newsId);
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.bookmarksKey);
  }
}

final readHistoryProvider = StateNotifierProvider<ReadHistoryNotifier, List<News>>((ref) {
  return ReadHistoryNotifier();
});

class ReadHistoryNotifier extends StateNotifier<List<News>> {
  ReadHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(AppConstants.readHistoryKey) ?? [];
    final history = historyJson
        .map((json) => News.fromJson(Map<String, dynamic>.from(_decodeJson(json))))
        .toList();
    state = history;
  }

  Map<String, dynamic> _decodeJson(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  String _encodeJson(News news) {
    return json.encode({
      'id': news.id,
      'title': news.title,
      'source': news.source,
      'sourceId': news.sourceId,
      'time': news.time,
      'url': news.url ?? '',
    });
  }

  Future<void> addToHistory(News news) async {
    if (news.id.isEmpty) return;
    
    final newHistory = [news, ...state.where((n) => n.id != news.id)];
    if (newHistory.length > AppConstants.maxReadHistoryCount) {
      state = newHistory.sublist(0, AppConstants.maxReadHistoryCount);
    } else {
      state = newHistory;
    }
    
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = state.map((news) => _encodeJson(news)).toList();
    await prefs.setStringList(AppConstants.readHistoryKey, historyJson);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.readHistoryKey);
  }
}

final followSourcesProvider = StateNotifierProvider<FollowSourcesNotifier, List<FollowSourceState>>((ref) {
  return FollowSourcesNotifier();
});

class FollowSourceState {
  final String id;
  final String name;
  final String type;
  final bool isSubscribed;

  FollowSourceState({
    required this.id,
    required this.name,
    required this.type,
    required this.isSubscribed,
  });

  FollowSourceState copyWith({bool? isSubscribed}) {
    return FollowSourceState(
      id: id,
      name: name,
      type: type,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

class FollowSourcesNotifier extends StateNotifier<List<FollowSourceState>> {
  FollowSourcesNotifier() : super([]) {
    _loadSources();
  }

  Future<void> _loadSources() async {
    final prefs = await SharedPreferences.getInstance();
    final subscribedIds = prefs.getStringList(AppConstants.subscriptionsKey) ?? [];
    
    final allSources = Sources.sources.entries
        .map((e) => FollowSourceState(
              id: e.key,
              name: e.value.name,
              type: e.value.type ?? 'hottest',
              isSubscribed: subscribedIds.isEmpty || subscribedIds.contains(e.key),
            ))
        .toList();
    
    state = allSources;
  }

  Future<void> toggleSubscription(String sourceId) async {
    state = state.map((s) {
      if (s.id == sourceId) {
        return s.copyWith(isSubscribed: !s.isSubscribed);
      }
      return s;
    }).toList();
    
    await _saveSubscriptions();
  }

  Future<void> _saveSubscriptions() async {
    final subscribedIds = state.where((s) => s.isSubscribed).map((s) => s.id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.subscriptionsKey, subscribedIds);
  }

  Future<void> selectAll() async {
    state = state.map((s) => s.copyWith(isSubscribed: true)).toList();
    await _saveSubscriptions();
  }

  Future<void> deselectAll() async {
    state = state.map((s) => s.copyWith(isSubscribed: false)).toList();
    await _saveSubscriptions();
  }

  List<FollowSourceState> get subscribedSources =>
      state.where((s) => s.isSubscribed).toList();

  List<String> get subscribedSourceIds =>
      state.where((s) => s.isSubscribed).map((s) => s.id).toList();
}

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

final scrollControllersProvider = Provider<Map<int, ScrollController>>((ref) {
  return {
    0: ScrollController(), // LiveScreen
    1: ScrollController(), // HotScreen
    2: ScrollController(), // FollowScreen
    3: ScrollController(), // ProfileScreen
  };
});
