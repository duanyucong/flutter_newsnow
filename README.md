# Flutter News

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

A modern news aggregation mobile app built with Flutter, based on the [NewsNow](https://github.com/ourongxing/newsnow) project. It provides an elegant reading experience for real-time and hottest news from various Chinese sources.

## Features

### Core Features
- **Multi-source News Aggregation** - Get news from 30+ popular Chinese platforms including Zhihu, Weibo, Baidu, Bilibili, 36Kr, GitHub, and more
- **Real-time Updates** - Stay informed with live news feeds
- **Clean Reading Experience** - Elegant UI design optimized for reading
- **Offline Reading** - Bookmark articles for later reading
- **Reading History** - Automatically track your reading history

### WebView Browser
- **Built-in Browser** - Read articles within the app using WebView
- **Customizable Browsing Settings**:
  - JavaScript toggle
  - Dark mode for web pages
  - Ad blocking
  - No-image mode (save data)
  - Desktop mode (desktop User-Agent)
  - Adjustable font size

### Personalization
- **Theme Support** - Light/Dark/System theme modes
- **Screen Rotation** - Portrait/Landscape/System rotation modes
- **Subscription Management** - Subscribe to your favorite news sources

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App constants
│   └── theme/              # Theme configuration
├── data/
│   ├── datasources/        # API clients
│   ├── models/             # Data models
│   └── repositories/      # Data repositories
├── presentation/
│   ├── screens/            # App screens
│   └── widgets/            # Reusable widgets
└── providers/              # Riverpod state management
```

## Supported News Sources

### Hot News
- 知乎 (Zhihu)
- 微博 (Weibo)
- 百度热搜 (Baidu)
- 抖音 (Douyin)
- 哔哩哔哩 (Bilibili)
- 豆瓣 (Douban)
- 虎扑 (Hupu)
- 36氪 (36Kr)
- GitHub Trending
- V2EX
- 少数派 (SSPaai)
- 稀土掘金 (Juejin)
- 雪球 (Xueqiu)
- 财联社 (CLS)
- 等等...

### Tech News
- IT之家 (IThome)
- 酷安 (CoolApk)
- 虎扑 (Hupu)
- FreeBuf

### Finance News
- 华尔街见闻 (WallStreetCN)
- 财联社 (CLS)
- 金十数据 (Jin10)
- 雪球 (Xueqiu)
- 格隆汇 (GeLongHui)

## Technology Stack

- **Framework**: Flutter 3.11+
- **State Management**: Riverpod
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences, Hive
- **WebView**: webview_flutter
- **Pinyin**: For Chinese pinyin conversion

## Getting Started

### Prerequisites

- Flutter SDK 3.11 or higher
- Android SDK / Xcode (for iOS)
- Dart 3.11 or higher

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-repo/flutter_news.git
cd flutter_news
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Configuration

### News API

The app uses the NewsNow API by default. You can configure a custom API endpoint in:

- `lib/core/constants/app_constants.dart`

### App Icons

Place your app icons in `assets/icons/` directory.

## Related Projects

- [NewsNow](https://github.com/ourongxing/newsnow) - The original web project this app is based on

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

Made with ❤️ using Flutter
