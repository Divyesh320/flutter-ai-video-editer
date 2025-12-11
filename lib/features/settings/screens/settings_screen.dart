import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/settings_notifier.dart';
import '../utils/account_deletion_utils.dart';
import '../utils/quota_utils.dart';
import '../widgets/quota_warning_banner.dart';
import '../widgets/settings_section.dart';
import '../widgets/usage_stats_card.dart';

/// Settings screen displaying usage stats, preferences, and account options
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsNotifierProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(settingsNotifierProvider.notifier).loadSettings();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Quota warning banner
                  if (state.showQuotaWarning && state.usageStats != null)
                    QuotaWarningBanner(
                      message: QuotaUtils.getWarningMessage(state.usageStats!)!,
                      isExceeded: state.isQuotaExceeded,
                      onDismiss: () {
                        ref.read(settingsNotifierProvider.notifier).dismissQuotaWarning();
                      },
                    ),

                  // Usage stats card
                  if (state.usageStats != null)
                    UsageStatsCard(stats: state.usageStats!),

                  const SizedBox(height: 24),

                  // Preferences section
                  SettingsSection(
                    title: 'Preferences',
                    children: [
                      SwitchListTile(
                        title: const Text('Text-to-Speech'),
                        subtitle: const Text('Read AI responses aloud'),
                        value: state.settings.ttsEnabled,
                        onChanged: (value) {
                          ref.read(settingsNotifierProvider.notifier).toggleTts();
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme'),
                        value: state.settings.darkMode,
                        onChanged: (value) {
                          ref.read(settingsNotifierProvider.notifier).toggleDarkMode();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Account section
                  SettingsSection(
                    title: 'Account',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () => _handleLogout(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => _handleDeleteAccount(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About section
                  SettingsSection(
                    title: 'About',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('App Version'),
                        trailing: const Text('1.0.0'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _openPrivacyPolicy(),
                      ),
                    ],
                  ),

                  // Error message
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Navigate to login screen
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await AccountDeletionUtils.showDeleteConfirmationDialog(context);

    if (confirmed && mounted) {
      final success = await ref.read(settingsNotifierProvider.notifier).deleteAccount();

      if (mounted) {
        if (success) {
          AccountDeletionUtils.showDeletionSuccessMessage(context);
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          final error = ref.read(settingsNotifierProvider).error ?? 'Unknown error';
          AccountDeletionUtils.showDeletionErrorMessage(context, error);
        }
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://example.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
