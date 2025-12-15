import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/services.dart';
import '../providers/video_editing_notifier.dart';

/// Screen for video editing
class VideoEditingScreen extends ConsumerStatefulWidget {
  const VideoEditingScreen({super.key});

  @override
  ConsumerState<VideoEditingScreen> createState() => _VideoEditingScreenState();
}

class _VideoEditingScreenState extends ConsumerState<VideoEditingScreen> {
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  
  double _startTime = 0;
  double _endTime = 10;
  String _selectedFilter = 'grayscale';
  double _filterIntensity = 1;
  String _textPosition = 'bottom';
  int _fontSize = 24;
  String _outputFormat = 'mp4';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoEditingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Editor'),
        actions: [
          if (state.selectedVideo != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(videoEditingNotifierProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FREE: Unlimited video editing with FFmpeg',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Video selection
            if (state.selectedVideo == null) ...[
              _buildVideoSelector(),
            ] else ...[
              _buildVideoInfo(state),
              const SizedBox(height: 16),
              _buildEditingOptions(state),
            ],

            // Loading indicator
            if (state.isLoading) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(state.currentOperation ?? 'Processing...'),
                  ],
                ),
              ),
            ],

            // Error message
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
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
            ],

            // Download button
            if (state.downloadUrl != null) ...[
              const SizedBox(height: 24),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Video processed successfully!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _downloadVideo(state.downloadUrl!),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSelector() {
    return Card(
      child: InkWell(
        onTap: _pickVideo,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Tap to select a video',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Supported: MP4, MOV, AVI, WebM',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(VideoEditingState state) {
    final metadata = state.metadata;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_file, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.selectedVideo!.path.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (metadata != null) ...[
              const Divider(),
              _buildMetadataRow('Duration', '${metadata.duration?.toStringAsFixed(1)}s'),
              _buildMetadataRow('Resolution', '${metadata.width}x${metadata.height}'),
              _buildMetadataRow('Format', metadata.format ?? 'Unknown'),
              _buildMetadataRow('Audio', metadata.hasAudio ? 'Yes' : 'No'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditingOptions(VideoEditingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trim section
        _buildSection(
          'Trim Video',
          Icons.content_cut,
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Start (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _startTime = double.tryParse(v) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'End (sec)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _endTime = double.tryParse(v) ?? 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  ref.read(videoEditingNotifierProvider.notifier)
                      .trimVideo(_startTime, _endTime);
                },
                child: const Text('Trim'),
              ),
            ],
          ),
        ),

        // Filter section
        _buildSection(
          'Apply Filter',
          Icons.filter,
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter',
                  border: OutlineInputBorder(),
                ),
                items: state.availableFilters.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(_formatName(f)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedFilter = v ?? 'grayscale'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Intensity:'),
                  Expanded(
                    child: Slider(
                      value: _filterIntensity,
                      min: 0.1,
                      max: 3,
                      divisions: 29,
                      label: _filterIntensity.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _filterIntensity = v),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  ref.read(videoEditingNotifierProvider.notifier)
                      .applyFilter(_selectedFilter, intensity: _filterIntensity);
                },
                child: const Text('Apply Filter'),
              ),
            ],
          ),
        ),

        // Text overlay section
        _buildSection(
          'Add Text',
          Icons.text_fields,
          Column(
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _textPosition,
                      decoration: const InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                      ),
                      items: ['top', 'center', 'bottom'].map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_formatName(p)),
                      )).toList(),
                      onChanged: (v) => setState(() => _textPosition = v ?? 'bottom'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Font Size',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _fontSize = int.tryParse(v) ?? 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  if (_textController.text.isNotEmpty) {
                    ref.read(videoEditingNotifierProvider.notifier)
                        .addTextOverlay(
                          _textController.text,
                          position: _textPosition,
                          fontSize: _fontSize,
                        );
                  }
                },
                child: const Text('Add Text'),
              ),
            ],
          ),
        ),

        // Extract audio section
        _buildSection(
          'Extract Audio',
          Icons.audiotrack,
          ElevatedButton(
            onPressed: state.isLoading ? null : () {
              ref.read(videoEditingNotifierProvider.notifier).extractAudio();
            },
            child: const Text('Extract as MP3'),
          ),
        ),

        // Convert format section
        _buildSection(
          'Convert Format',
          Icons.transform,
          Column(
            children: [
              DropdownButtonFormField<String>(
                value: _outputFormat,
                decoration: const InputDecoration(
                  labelText: 'Output Format',
                  border: OutlineInputBorder(),
                ),
                items: ['mp4', 'webm', 'avi', 'mov', 'gif'].map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f.toUpperCase()),
                )).toList(),
                onChanged: (v) => setState(() => _outputFormat = v ?? 'mp4'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  ref.read(videoEditingNotifierProvider.notifier)
                      .convertFormat(_outputFormat);
                },
                child: const Text('Convert'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  String _formatName(String name) {
    return name.split('-').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      ref.read(videoEditingNotifierProvider.notifier).selectVideo(File(video.path));
    }
  }

  Future<void> _downloadVideo(String downloadUrl) async {
    final baseUrl = ApiConfig.fromEnv().baseUrl;
    final fullUrl = '$baseUrl$downloadUrl';
    
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
