import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/sources.dart';
import '../../providers/providers.dart';
import '../widgets/news_card.dart';
import 'webview_screen.dart';

class HotScreen extends ConsumerWidget {
  const HotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(hotNewsProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // _buildHeader(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(hotNewsProvider.notifier).refresh();
              },
              child: () {
                final scrollController = ref.watch(scrollControllersProvider)[1];
                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '热点',
                              style: theme.textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    newsAsync.when(
                      loading: () => const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      error: (error, _) => SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Text('加载失败: $error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => ref.read(hotNewsProvider.notifier).refresh(),
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      data: (news) => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == news.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: Text('没有更多了'),
                                  ),
                                );
                              }
                              final item = news[index];
                              final sourceConfig = Sources.getSource(item.sourceId);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NewsCard(
                                  news: item,
                                  onTap: () => _openWebView(context, item, sourceConfig),
                                ),
                              );
                            },
                            childCount: news.length + 1,
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ Color(0x00000000), Color(0x00000000)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Image(
                    image: AssetImage('assets/icons/app_icon.png'),
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              Text(
                'NewsNow',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 22,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWebView(BuildContext context, dynamic item, SourceConfig? sourceConfig) {
    final url = item.url;
    if (url != null && url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: url,
            title: sourceConfig?.name ?? item.source,
            news: item,
          ),
        ),
      );
    }
  }
}
