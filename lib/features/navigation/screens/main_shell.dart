import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/screens/chat_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'home_screen.dart';

/// Provider for current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for deep link conversation ID
final deepLinkConversationProvider = StateProvider<String?>((ref) => null);

/// Main shell widget with bottom navigation
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final deepLinkConversationId = ref.watch(deepLinkConversationProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          const HomeScreen(),
          ChatScreen(conversationId: deepLinkConversationId),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          // Clear deep link when navigating away from chat
          if (index != 1) {
            ref.read(deepLinkConversationProvider.notifier).state = null;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      // floatingActionButton: const RadialFabMenu(),
    );
  }

  /// Navigate to chat with a specific conversation
  static void navigateToConversation(WidgetRef ref, String conversationId) {
    ref.read(deepLinkConversationProvider.notifier).state = conversationId;
    ref.read(navigationIndexProvider.notifier).state = 1;
  }

  /// Navigate to a new chat
  static void navigateToNewChat(WidgetRef ref) {
    ref.read(deepLinkConversationProvider.notifier).state = null;
    ref.read(navigationIndexProvider.notifier).state = 1;
  }
}
