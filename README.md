# Flutter News

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue.svg)
![Version](https://img.shields.io/badge/version-1.0.0-green.svg)

一款基于 [NewsNow](https://github.com/ourongxing/newsnow) 项目开发的现代化新闻聚合移动应用。为用户提供来自各类中文资讯源的实时新闻和热门排行榜阅读体验。

## 功能特性

### 核心功能
- **多源资讯聚合** - 汇聚知乎、微博、百度、抖音、B站、36氪、GitHub 等 30+ 热门中文平台的新闻资讯
- **实时热点更新** - 实时追踪热门话题和最新资讯
- **极简阅读体验** - 优雅的 UI 设计，专注内容阅读
- **离线收藏** - 收藏感兴趣的文章随时阅读
- **阅读历史** - 自动记录阅读轨迹

### 内置浏览器
- **WebView 浏览** - 在应用内直接浏览网页文章
- **自定义浏览设置**：
  - JavaScript 开关
  - 网页暗黑模式
  - 广告拦截
  - 无图模式（省流量）
  - 桌面版模式（桌面端 User-Agent）
  - 字体大小调节

### 个性化定制
- **主题模式** - 浅色/深色/跟随系统
- **屏幕旋转** - 竖屏/横屏/跟随系统
- **订阅管理** - 自由订阅感兴趣的资讯源

## 项目结构

```
lib/
├── core/
│   ├── constants/          # 应用常量
│   └── theme/              # 主题配置
├── data/
│   ├── datasources/        # API 客户端
│   ├── models/            # 数据模型
│   └── repositories/       # 数据仓库
├── presentation/
│   ├── screens/           # 页面组件
│   └── widgets/           # 通用组件
└── providers/             # Riverpod 状态管理
```

## 支持的资讯源

### 热门资讯
- 知乎
- 微博
- 百度热搜
- 抖音
- 哔哩哔哩
- 豆瓣
- 虎扑
- 36氪
- GitHub Trending
- V2EX
- 少数派
- 稀土掘金
- 雪球
- 财联社
- 等等...

### 科技资讯
- IT之家
- 酷安
- FreeBuf

### 财经资讯
- 华尔街见闻
- 财联社
- 金十数据
- 雪球
- 格隆汇

## 技术栈

- **框架**: Flutter 3.11+
- **状态管理**: Riverpod
- **网络请求**: Dio
- **本地存储**: SharedPreferences, Hive
- **网页浏览**: webview_flutter
- **拼音转换**: pinyin

## 快速开始

### 环境要求

- Flutter SDK 3.11 或更高版本
- Android SDK / Xcode（用于 iOS 开发）
- Dart 3.11 或更高版本

### 安装部署

1. 克隆项目：
```bash
git clone https://github.com/your-repo/flutter_news.git
cd flutter_news
```

2. 安装依赖：
```bash
flutter pub get
```

3. 运行应用：
```bash
flutter run
```

### 构建发布

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 配置说明

### 新闻 API

应用默认使用 NewsNow API。如需自定义 API 端点，可修改：

- `lib/core/constants/app_constants.dart`

### 应用图标

将应用图标放置在 `assets/icons/` 目录下。

## 相关项目

- [NewsNow](https://github.com/ourongxing/newsnow) - 本项目基于的网页版新闻聚合应用

## 开源许可

本项目基于 MIT 许可证开源，详见 LICENSE 文件。

## 贡献代码

欢迎提交 Pull Request 或创建 Issue！

---

使用 ❤️ 基于 Flutter 开发
