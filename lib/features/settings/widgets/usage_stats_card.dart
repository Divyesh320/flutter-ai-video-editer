import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/settings_models.dart';
import '../utils/quota_utils.dart';

/// Card displaying user usage statistics
class UsageStatsCard extends StatelessWidget {
  const UsageStatsCard({
    super.key,
    required this.stats,
  });

  final UsageStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usagePercentage = stats.usagePercentage;
    final progressColor = _getProgressColor(usagePercentage);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quota Usage',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      QuotaUtils.getUsagePercentageText(stats),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usagePercentage.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                const SizedBox(height: 4),
                Text(
                  QuotaUtils.getRemainingQuotaText(stats),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    value: stats.messageCount.toString(),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.cloud_upload_outlined,
                    label: 'Uploads',
                    value: stats.mediaUploads.toString(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Reset date
            Row(
              children: [
                Icon(
                  Icons.refresh,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resets on ${DateFormat.yMMMd().format(stats.resetDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) {
      return Colors.red;
    } else if (percentage >= 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
