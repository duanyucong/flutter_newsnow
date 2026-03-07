import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sources.dart';
import '../../providers/providers.dart';
import '../widgets/news_card.dart';
import 'webview_screen.dart';

class HotScreen extends ConsumerWidget {
  const HotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(hotNewsProvider);
    final isRefreshing = ref.watch(hotIsRefreshingProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
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
                              '热点',
                              style: theme.textTheme.headlineLarge,
                            ),
                            centerTitle: false,
                            titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                          ),
                        ),
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
