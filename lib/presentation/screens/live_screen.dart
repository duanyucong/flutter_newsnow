import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/sources.dart';
import '../../providers/providers.dart';
import '../widgets/news_card.dart';
import 'webview_screen.dart';

class LiveScreen extends ConsumerWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(liveNewsProvider);
    final isRefreshing = ref.watch(liveIsRefreshingProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await ref.read(liveNewsProvider.notifier).refresh();
            },
            child: newsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('加载失败: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(liveNewsProvider.notifier).refresh(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (news) {
                final scrollController = ref.watch(scrollControllersProvider)[0];
                return CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      snap: false,
                      expandedHeight: 80,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          '实时',
                          style: theme.textTheme.headlineLarge,
                        ),
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == news.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: Text('暂无更多')),
                              );
                            }
                            final item = news[index];
                            final sourceConfig = Sources.getSource(item.sourceId);
                            return _buildTimelineItem(context, item, sourceConfig);
                          },
                          childCount: news.length + 1,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
            ),
          ),
          if (isRefreshing)
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, dynamic item, SourceConfig? sourceConfig) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                item.time,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.dividerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NewsCard(
                news: item,
                onTap: () => _openWebView(context, item, sourceConfig),
              ),
            ),
          ],
        ),
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
