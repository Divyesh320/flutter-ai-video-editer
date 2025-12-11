import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../chat/providers/conversation_notifier.dart';
import '../../chat/providers/conversation_state.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_loader.dart';
import 'main_shell.dart';

/// Home screen with recent conversations and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationNotifierProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationState = ref.watch(conversationNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multimodal AI Assistant'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(conversationNotifierProvider.notifier).loadConversations();
        },
        child: CustomScrollView(
          slivers: [
            // Quick Actions Section
            SliverToBoxAdapter(
              child: _buildQuickActionsSection(context, theme),
            ),
            // Recent Conversations Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Conversations',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(navigationIndexProvider.notifier).state = 1;
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            // Recent Conversations List
            _buildConversationsList(conversationState, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.chat,
                  label: 'New Chat',
                  color: theme.colorScheme.primary,
                  onTap: () => MainShell.navigateToNewChat(ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.mic,
                  label: 'Voice',
                  color: Colors.orange,
                  onTap: () => _startVoiceChat(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.image,
                  label: 'Image',
                  color: Colors.green,
                  onTap: () => _startImageChat(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.purple,
                  onTap: () => _startVideoChat(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(ConversationListState state, ThemeData theme) {
    if (state.isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const SkeletonLoader(type: SkeletonType.listTile),
          childCount: 5,
        ),
      );
    }

    if (state.hasError) {
      return SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Failed to load conversations',
          subtitle: state.errorMessage ?? 'Please try again',
          actionLabel: 'Retry',
          onAction: () {
            ref.read(conversationNotifierProvider.notifier).loadConversations();
          },
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyStateWidget(
          icon: Icons.chat_bubble_outline,
          title: 'No conversations yet',
          subtitle: 'Start a new conversation using the quick actions above',
        ),
      );
    }

    // Show only recent 5 conversations
    final recentConversations = state.conversations.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final conversation = recentConversations[index];
          return _buildConversationTile(conversation, theme);
        },
        childCount: recentConversations.length,
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation, ThemeData theme) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.chat,
          color: theme.colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        conversation.title ?? 'New Conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.lastMessagePreview ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _formatTimestamp(conversation.updatedAt),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      onTap: () => MainShell.navigateToConversation(ref, conversation.id),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat.jm().format(timestamp);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat.EEEE().format(timestamp);
    } else {
      return DateFormat.MMMd().format(timestamp);
    }
  }

  void _startVoiceChat() {
    MainShell.navigateToNewChat(ref);
    // Voice recording will be triggered from the chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the microphone button to start voice input'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startImageChat() {
    MainShell.navigateToNewChat(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the image button to upload an image'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _startVideoChat() {
    MainShell.navigateToNewChat(ref);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use the video button to upload a video'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
