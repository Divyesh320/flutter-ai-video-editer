import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/image_generation_notifier.dart';

/// Screen for AI image generation
class ImageGenerationScreen extends ConsumerStatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  ConsumerState<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends ConsumerState<ImageGenerationScreen> {
  final _promptController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenerationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Generator'),
        actions: [
          if (state.generatedImage != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareImage(state.generatedImage!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Credits info card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.credits != null
                              ? 'Credits: ${state.credits!.toStringAsFixed(1)} remaining'
                              : 'FREE: 25 images/month with Stability AI',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      // Refresh credits button
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
                        onPressed: () {
                          ref.read(imageGenerationNotifierProvider.notifier).loadCredits();
                        },
                        tooltip: 'Refresh credits',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Prompt input
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Describe your image',
                  hintText: 'A sunset over mountains with a lake...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Style selector
              DropdownButtonFormField<String>(
                value: state.style,
                decoration: const InputDecoration(
                  labelText: 'Style',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette),
                ),
                items: (state.availableStyles.isEmpty
                    ? ['photographic', 'digital-art', 'anime', 'cinematic']
                    : state.availableStyles)
                    .map((style) => DropdownMenuItem(
                          value: style,
                          child: Text(_formatStyleName(style)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(imageGenerationNotifierProvider.notifier).setStyle(value);
                  }
                },
              ),
              const SizedBox(height: 24),

              // Generate button
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _generateImage,
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(state.isLoading ? 'Generating...' : 'Generate Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (state.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Generated image
              if (state.generatedImage != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    state.generatedImage!,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.prompt != null)
                  Text(
                    'Prompt: ${state.prompt}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _saveImage(state.generatedImage!),
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(imageGenerationNotifierProvider.notifier).clearImage();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ],

              // Loading placeholder
              if (state.isLoading && state.generatedImage == null) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Creating your image...'),
                      SizedBox(height: 8),
                      Text(
                        'This may take 10-30 seconds',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _generateImage() {
    if (_formKey.currentState!.validate()) {
      ref.read(imageGenerationNotifierProvider.notifier).generateImage(
        _promptController.text.trim(),
      );
    }
  }

  String _formatStyleName(String style) {
    return style.split('-').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Future<void> _saveImage(List<int> imageBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ai_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(imageBytes);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved: $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image')),
        );
      }
    }
  }

  Future<void> _shareImage(List<int> imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/ai_image.png');
      await file.writeAsBytes(imageBytes);
      
      await Share.shareXFiles([XFile(file.path)], text: 'AI Generated Image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share image')),
        );
      }
    }
  }
}
