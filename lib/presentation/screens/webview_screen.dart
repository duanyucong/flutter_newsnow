import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../data/models/news.dart';
import '../../providers/providers.dart';
import 'browser_settings_screen.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final News? news;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.news,
  });

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _pageLoaded = false;
  String? _lastError;
  String? _currentUrl;
  String? _blockedUrl;
  Timer? _loadingTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  late bool _isDarkMode;
  String? _lastNavigatedUrl;
  int _redirectCount = 0;
  late WebViewSettings _webViewSettings;

  final List<String> _blockedSchemes = [
    'zhihu://',
    'weibo://',
    'douyin://',
    'baidu://',
    'bilibili://',
    'toutiao://',
    'bytedance://',
    'intent://',
    'toutiaoshare://',
    'snssdk://',
  ];

  @override
  void initState() {
    super.initState();
    _webViewSettings = ref.read(webViewSettingsProvider);
    _isDarkMode = _calculateIsDarkMode() || _webViewSettings.darkModeEnabled;
    _recordReadHistory();
    _initWebView();
  }

  bool _calculateIsDarkMode() {
    final themeMode = ref.read(themeModeProvider);
    if (themeMode == AppThemeMode.dark) return true;
    if (themeMode == AppThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _recordReadHistory() {
    if (widget.news != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(readHistoryProvider.notifier).addToHistory(widget.news!);
      });
    }
  }

  void _initWebView() {
    final bgColor = _isDarkMode ? Colors.black : Colors.white;
    
    final userAgent = _webViewSettings.desktopMode
        ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        : 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';
    
    _controller = WebViewController()
      ..setJavaScriptMode(_webViewSettings.javascriptEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setUserAgent(userAgent)
      ..setBackgroundColor(bgColor)
      ..enableZoom(!_webViewSettings.noImageMode)
      ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
        // 过滤掉已知的非关键错误日志
        final ignoredPatterns = [
          "Failed to execute 'write' on 'Document'",
          "count.php",
        ];
        final shouldIgnore = ignoredPatterns.any(
          (pattern) => message.message.contains(pattern),
        );
        if (!shouldIgnore) {
          debugPrint('WebView Console [${message.level.name}]: ${message.message}');
        }
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('WebView loading: $url');
            setState(() {
              _isLoading = true;
              _hasError = false;
              _pageLoaded = false;
              _lastError = null;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            debugPrint('WebView finished: $url');
            _loadingTimer?.cancel();
            setState(() {
              _isLoading = false;
              _pageLoaded = true;
              _currentUrl = url;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _injectDarkModeCss();
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.errorType} - ${error.description} (isMainFrame: ${error.isForMainFrame})');
            
            // 页面已加载完成，忽略资源错误（如图片、广告等加载失败）
            if (_pageLoaded) {
              debugPrint('Page already loaded, ignoring resource error');
              return;
            }
            
            // 非主框架的错误（如 iframe、图片、脚本等），不视为页面加载失败
            if (error.isForMainFrame == false) {
              debugPrint('Non-main frame error, ignoring');
              return;
            }
            
            final isConnectionReset = error.description.contains('ERR_CONNECTION_RESET') ||
                error.description.contains('net::ERR_CONNECTION_RESET');
            
            if (isConnectionReset) {
              _loadingTimer?.cancel();
              _attemptRetry(widget.url);
              return;
            }
            
            final isTimeout = error.description.contains('ERR_TIMED_OUT') ||
                error.description.contains('net::ERR_CONNECTION_TIMED_OUT');
            
            if (isTimeout) {
              _loadingTimer?.cancel();
              _attemptRetry(widget.url);
              return;
            }
            
            _controller.loadHtmlString('<html><body></body></html>');
            setState(() {
              _hasError = true;
              _isLoading = false;
              _lastError = error.description;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('WebView navigation: $url');
            
            if (_isAppScheme(url)) {
              _showBlockedBanner(url);
              return NavigationDecision.prevent;
            }
            
            if (_lastNavigatedUrl != null) {
              final lastUri = Uri.tryParse(_lastNavigatedUrl!);
              final currentUri = Uri.tryParse(url);
              if (lastUri != null && currentUri != null) {
                if (lastUri.host == currentUri.host && 
                    _normalizePath(lastUri.path) == _normalizePath(currentUri.path)) {
                  _redirectCount++;
                  if (_redirectCount > 2) {
                    debugPrint('Prevented infinite redirect loop');
                    return NavigationDecision.prevent;
                  }
                } else {
                  _redirectCount = 0;
                }
              }
            }
            _lastNavigatedUrl = url;
            
            return NavigationDecision.navigate;
          },
        ),
      );
    
    debugPrint('WebView loading: ${widget.url}');
    _loadUrl();
  }

  Future<void> _injectDarkModeCss() async {
    final noImageMode = _webViewSettings.noImageMode;
    final darkMode = _isDarkMode;
    final textSize = _webViewSettings.textSize;
    
    var css = '';
    
    if (darkMode) {
      css += '''
        html {
          filter: invert(1) hue-rotate(180deg) !important;
          background-color: #000 !important;
        }
        img, video, picture, canvas, svg, [style*="background-image"] {
          filter: invert(1) hue-rotate(180deg) !important;
        }
        body {
          background-color: #000 !important;
        }
      ''';
    }
    
    if (noImageMode) {
      css += '''
        img, picture, video, canvas, svg, [style*="background-image"], 
        iframe[src*=".jpg"], iframe[src*=".jpeg"], iframe[src*=".png"], 
        iframe[src*=".gif"], iframe[src*=".webp"] {
          display: none !important;
          visibility: hidden !important;
        }
      ''';
    }
    
    if (textSize != 16) {
      css += '''
        html {
          font-size: ${textSize}px !important;
        }
        body, p, span, div, article, section, li, td, th {
          font-size: inherit !important;
          line-height: inherit !important;
        }
      ''';
    }
    
    if (_webViewSettings.adBlockEnabled) {
      css += '''
        [id*="google_ads"], [id*="ads-container"], [class*="ads-"], [class*="advertisement"],
        .ad-container, .ad-wrapper, .ad-banner, .ad-box, .ad-slot, .adsbygoogle,
        .sponsored, .sponsored-content, .promotion, .promo-banner,
        ins.adsbygoogle, div[id^="google_ads"], iframe[src*="doubleclick"],
        iframe[src*="googlesyndication"], iframe[src*="googleadservices"],
        [class*="banner-ad"], [id*="banner-ad"], .ad-popup, .ad-modal {
          display: none !important;
          visibility: hidden !important;
          height: 0 !important;
          width: 0 !important;
          overflow: hidden !important;
        }
      ''';
    }
    
    if (darkMode || noImageMode || textSize != 16) {
      await _controller.runJavaScript('''
        (function() {
          var existingStyle = document.getElementById('webview-style');
          if (!existingStyle) {
            var style = document.createElement('style');
            style.id = 'webview-style';
            document.head.appendChild(style);
          }
          var style = document.getElementById('webview-style');
          style.innerHTML = `$css`;
          
          // 监听新加载的图片并隐藏（仅在无图模式下）
          if (window.imageObserver) {
            window.imageObserver.disconnect();
          }
          ${noImageMode ? '''
          window.imageObserver = new MutationObserver(function(mutations) {
            var elements = document.querySelectorAll('img, picture, video, [style*="background-image"]');
            elements.forEach(function(el) {
              el.style.display = 'none';
              el.style.visibility = 'hidden';
            });
          });
          window.imageObserver.observe(document.body, { 
            childList: true, 
            subtree: true,
            attributes: true,
            attributeFilter: ['src', 'style']
          });
          ''' : ''}
        })();
      ''');
    } else {
      await _controller.runJavaScript('''
        (function() {
          var style = document.getElementById('webview-style');
          if (style) {
            style.innerHTML = '';
          }
          if (window.imageObserver) {
            window.imageObserver.disconnect();
            window.imageObserver = null;
          }
        })();
      ''');
    }
  }

  Future<void> _loadUrl() async {
    if (widget.url.isEmpty) {
      setState(() {
        _hasError = true;
        _lastError = '无效的链接';
      });
      return;
    }
    
    _pageLoaded = false;
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (_isLoading && !_hasError && !_pageLoaded) {
        debugPrint('Loading timeout, showing error page');
        setState(() {
          _hasError = true;
          _isLoading = false;
          _lastError = '网页加载超时';
        });
      }
    });
    
    try {
      await _controller.loadRequest(Uri.parse(widget.url));
    } catch (e) {
      debugPrint('Load request failed: $e');
      _loadingTimer?.cancel();
      setState(() {
        _hasError = true;
        _isLoading = false;
        _lastError = e.toString();
      });
    }
  }

  Future<void> _loadUrlWithRetry(String url, {bool isRetry = false}) async {
    _pageLoaded = false;
    _loadingTimer?.cancel();
    
    if (!isRetry) {
      _retryCount = 0;
    }
    
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (_isLoading && !_hasError && !_pageLoaded) {
        debugPrint('Loading timeout, attempting retry ${_retryCount + 1}/$_maxRetries');
        _attemptRetry(url);
      }
    });
    
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Load request failed: $e');
      _loadingTimer?.cancel();
      _attemptRetry(url);
    }
  }

  void _attemptRetry(String url) {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Retrying... attempt $_retryCount/$_maxRetries');
      
      // 延迟重试，给网络一些恢复时间
      Future.delayed(Duration(seconds: _retryCount), () {
        if (mounted) {
          // 尝试使用不同协议
          String retryUrl = url;
          if (url.startsWith('https://') && _retryCount == 1) {
            retryUrl = url.replaceFirst('https://', 'http://');
            debugPrint('Switching to HTTP: $retryUrl');
          }
          _loadUrlWithRetry(retryUrl, isRetry: true);
        }
      });
    } else {
      // 重试次数用尽，显示错误
      _controller.loadHtmlString('<html><body></body></html>');
      setState(() {
        _hasError = true;
        _isLoading = false;
        _lastError = '网络连接失败，请检查网络后重试';
      });
    }
  }

  bool _isAppScheme(String url) {
    for (final scheme in _blockedSchemes) {
      if (url.startsWith(scheme)) {
        return true;
      }
    }
    return false;
  }

  String _normalizePath(String path) {
    return path.replaceAll(RegExp(r'^/+'), '').replaceAll(RegExp(r'/+$'), '');
  }

  void _showBlockedBanner(String url) {
    setState(() {
      _blockedUrl = url;
    });
  }

  void _hideBlockedBanner() {
    setState(() {
      _blockedUrl = null;
    });
  }

  void _openBlockedUrl() {
    if (_blockedUrl != null) {
      _openInBrowser(_blockedUrl);
      _hideBlockedBanner();
    }
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    if (_pageLoaded) {
      _injectDarkModeCss();
    }
  }

  Future<void> _openInBrowser(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      debugPrint('Attempting to open URL: $url');
      
      final canLaunch = await canLaunchUrl(uri);
      debugPrint('Can launch URL: $canLaunch');
      
      if (canLaunch) {
        debugPrint('Launching URL with mode: LaunchMode.externalApplication');
        final result = await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Launch result: $result');
      } else {
        debugPrint('Cannot launch URL: $url');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开链接')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text('无效的链接'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            if (_currentUrl != null)
              Text(
                _currentUrl!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasError = false;
                _pageLoaded = false;
                _lastError = null;
                _isLoading = true;
                _retryCount = 0;
              });
              _controller.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => _openInBrowser(widget.url),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'back':
                  _controller.goBack();
                  break;
                case 'forward':
                  _controller.goForward();
                  break;
                case 'browser':
                  _openInBrowser(widget.url);
                  break;
                case 'darkMode':
                  _toggleDarkMode();
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BrowserSettingsScreen()),
                  ).then((_) {
                    // 设置更改后重新初始化 WebView
                    final newSettings = ref.read(webViewSettingsProvider);
                    final newDarkMode = _calculateIsDarkMode() || newSettings.darkModeEnabled;
                    if (newSettings.javascriptEnabled != ref.read(webViewSettingsProvider).javascriptEnabled ||
                        newSettings.desktopMode != ref.read(webViewSettingsProvider).desktopMode ||
                        newSettings.noImageMode != ref.read(webViewSettingsProvider).noImageMode ||
                        newDarkMode != _isDarkMode) {
                      setState(() {
                        _isDarkMode = newDarkMode;
                      });
                      _initWebView();
                    }
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'back',
                child: Row(
                  children: [
                    Icon(Icons.arrow_back),
                    SizedBox(width: 8),
                    Text('后退'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward),
                    SizedBox(width: 8),
                    Text('前进'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'browser',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser),
                    SizedBox(width: 8),
                    Text('用浏览器打开'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'darkMode',
                child: Row(
                  children: [
                    Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 8),
                    Text(_isDarkMode ? '浅色模式' : '深色模式'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('浏览设置'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Positioned.fill(child: _buildErrorView())
          else
            WebViewWidget(controller: _controller),

          if (_blockedUrl != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBlockedBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          top: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已阻止跳转: $_blockedUrl',
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _openBlockedUrl,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '用浏览器打开',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _hideBlockedBanner,
            icon: Icon(Icons.close, color: Colors.orange.shade800, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '无法加载网页',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _lastError ?? '网络连接失败',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentUrl = '';
                        _lastError = null;
                        _isLoading = true;
                      });
                      _controller.reload();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openInBrowser(widget.url),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('用浏览器打开'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
