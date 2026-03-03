import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'hot_screen.dart';
import 'live_screen.dart';
import 'follow_screen.dart';
import 'profile_screen.dart';

final currentNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          LiveScreen(),
          HotScreen(),
          FollowScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(currentNavIndexProvider.notifier).state = index;
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time_filled),
              label: '实时',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.whatshot_outlined),
              activeIcon: Icon(Icons.whatshot),
              label: '热点',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: '关注',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '个人',
            ),
          ],
        ),
      ),
    );
  }
}
