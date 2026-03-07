import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sources.dart';
import '../../providers/providers.dart';
import '../widgets/follow_nav.dart';
import '../widgets/news_card.dart';
import 'webview_screen.dart';

class FollowScreen extends ConsumerWidget {
  const FollowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(followNewsProvider);
    final followSources = ref.watch(followSourcesProvider);
    final selectedSource = ref.watch(followSourceProvider);
    final isRefreshing = ref.watch(followIsRefreshingProvider);

    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              FollowNav(
                sources: followSources,
                selectedSource: selectedSource,
                onSourceSelected: (sourceId) {
                  ref.read(followSourceProvider.notifier).state = sourceId;
                },
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(followNewsProvider.notifier).refresh();
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
                            onPressed: () => ref.read(followNewsProvider.notifier).refresh(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                    data: (news) {
                      final scrollController = ref.watch(scrollControllersProvider)[2];
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: news.length + 1,
                        itemBuilder: (context, index) {
                          if (index == news.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('暂无更多')),
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
                      );
                    },
                  ),
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
