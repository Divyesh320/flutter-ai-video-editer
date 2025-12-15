import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../chat/providers/conversation_notifier.dart';
import '../../chat/providers/conversation_state.dart';
import '../../chat/screens/model_comparison_screen.dart';
import '../../image_generation/screens/image_generation_screen.dart';
import '../../video_editing/screens/video_editing_screen.dart';
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
          // First row
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.chat,
                  label: 'Chat',
                  color: theme.colorScheme.primary,
                  onTap: () => MainShell.navigateToNewChat(ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.compare_arrows,
                  label: 'Compare AI',
                  color: Colors.teal,
                  onTap: () => _openModelComparison(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row
          Row(
            children: [
              Expanded(
                child: QuickActionButton(
                  icon: Icons.auto_awesome,
                  label: 'Generate Image',
                  color: Colors.purple,
                  onTap: () => _openImageGeneration(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QuickActionButton(
                  icon: Icons.movie_edit,
                  label: 'Edit Video',
                  color: Colors.orange,
                  onTap: () => _openVideoEditing(),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(conversation.updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.outline),
            onSelected: (value) {
              switch (value) {
                case 'rename':
                  _showRenameDialog(conversation);
                  break;
                case 'delete':
                  _showDeleteDialog(conversation);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Rename'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => MainShell.navigateToConversation(ref, conversation.id),
    );
  }

  void _showRenameDialog(Conversation conversation) {
    final controller = TextEditingController(text: conversation.title ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chat Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                await ref.read(conversationNotifierProvider.notifier)
                    .renameConversation(conversation.id, newTitle);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete "${conversation.title ?? 'this chat'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(conversationNotifierProvider.notifier)
                  .deleteConversation(conversation.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

  void _openModelComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ModelComparisonScreen(),
      ),
    );
  }

  void _openImageGeneration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ImageGenerationScreen(),
      ),
    );
  }

  void _openVideoEditing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoEditingScreen(),
      ),
    );
  }
}
