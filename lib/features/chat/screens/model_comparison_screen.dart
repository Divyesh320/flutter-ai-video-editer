import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_notifier.dart';
import '../services/multi_model_service.dart';

/// Provider for MultiModelService
final multiModelServiceProvider = Provider<MultiModelService>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return MultiModelService(apiService: apiService);
});

/// Screen to compare responses from multiple AI models
class ModelComparisonScreen extends ConsumerStatefulWidget {
  const ModelComparisonScreen({super.key});

  @override
  ConsumerState<ModelComparisonScreen> createState() => _ModelComparisonScreenState();
}

class _ModelComparisonScreenState extends ConsumerState<ModelComparisonScreen> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  MultiModelResult? _result;
  String? _error;
  List<AIModelInfo> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final service = ref.read(multiModelServiceProvider);
    final models = await service.getModels();
    setState(() => _availableModels = models);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _availableModels.where((m) => m.enabled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showModelsInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$enabledCount FREE AI models enabled - Best response auto-selected',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // Input section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Ask anything...',
                    hintText: 'Compare how different AI models answer your question',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _compareModels(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _compareModels,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.compare_arrows),
                    label: Text(_isLoading ? 'Comparing...' : 'Compare All Models'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),

          // Results
          if (_result != null)
            Expanded(
              child: _buildResults(),
            ),

          // Loading indicator
          if (_isLoading && _result == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Querying all AI models...'),
                    SizedBox(height: 8),
                    Text(
                      'This may take 5-15 seconds',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'Best: ${result.bestResponse?.model ?? "None"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.responses.length} models responded in ${result.totalTime}ms',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                if (result.failed.isNotEmpty)
                  Text(
                    '${result.failed.length} models failed',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // All responses
        ...result.responses.map((response) => _buildResponseCard(response)),

        // Failed models
        if (result.failed.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Failed Models',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          ...result.failed.map((f) => Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(f.model),
              subtitle: Text(f.error ?? 'Unknown error'),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildResponseCard(ModelResponse response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: response.isBest
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: response.isBest ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (response.isBest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'BEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    response.model,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${response.responseTime}ms',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(response.content),
                  tooltip: 'Copy',
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              response.content,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _compareModels() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(multiModelServiceProvider);
      final result = await service.compare(prompt);
      
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _showModelsInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available FREE AI Models',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_availableModels.isEmpty)
              const Text('Loading models...')
            else
              ..._availableModels.map((m) => ListTile(
                leading: Icon(
                  m.enabled ? Icons.check_circle : Icons.cancel,
                  color: m.enabled ? Colors.green : Colors.grey,
                ),
                title: Text(m.displayName),
                subtitle: Text(m.provider),
                trailing: Text(m.enabled ? 'Enabled' : 'No API Key'),
              )),
            const SizedBox(height: 16),
            const Text(
              'Add API keys in backend .env file to enable more models',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
