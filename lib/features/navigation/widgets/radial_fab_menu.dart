import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/main_shell.dart';

/// Provider for FAB menu open state
final fabMenuOpenProvider = StateProvider<bool>((ref) => false);

/// Radial floating action button menu with multimodal options
class RadialFabMenu extends ConsumerStatefulWidget {
  const RadialFabMenu({super.key});

  @override
  ConsumerState<RadialFabMenu> createState() => _RadialFabMenuState();
}

class _RadialFabMenuState extends ConsumerState<RadialFabMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  final List<_FabMenuItem> _menuItems = [
    _FabMenuItem(
      icon: Icons.chat,
      label: 'Text Chat',
      color: Colors.blue,
      action: FabAction.textChat,
    ),
    _FabMenuItem(
      icon: Icons.mic,
      label: 'Voice',
      color: Colors.orange,
      action: FabAction.voice,
    ),
    _FabMenuItem(
      icon: Icons.image,
      label: 'Image',
      color: Colors.green,
      action: FabAction.image,
    ),
    _FabMenuItem(
      icon: Icons.videocam,
      label: 'Video',
      color: Colors.purple,
      action: FabAction.video,
    ),
    _FabMenuItem(
      icon: Icons.email,
      label: 'Email',
      color: Colors.red,
      action: FabAction.email,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final isOpen = ref.read(fabMenuOpenProvider);
    if (isOpen) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    ref.read(fabMenuOpenProvider.notifier).state = !isOpen;
  }

  void _close() {
    _controller.reverse();
    ref.read(fabMenuOpenProvider.notifier).state = false;
  }

  void _handleAction(FabAction action) {
    _close();
    
    switch (action) {
      case FabAction.textChat:
        MainShell.navigateToNewChat(ref);
        break;
      case FabAction.voice:
        MainShell.navigateToNewChat(ref);
        _showSnackBar('Use the microphone button to start voice input');
        break;
      case FabAction.image:
        MainShell.navigateToNewChat(ref);
        _showSnackBar('Use the image button to upload an image');
        break;
      case FabAction.video:
        MainShell.navigateToNewChat(ref);
        _showSnackBar('Use the video button to upload a video');
        break;
      case FabAction.email:
        MainShell.navigateToNewChat(ref);
        _showSnackBar('Start a conversation, then use the email action');
        break;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(fabMenuOpenProvider);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Backdrop
          if (isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(color: Colors.transparent),
              ),
            ),
          // Menu items
          ..._buildMenuItems(),
          // Main FAB
          FloatingActionButton(
            onPressed: _toggle,
            child: AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _expandAnimation.value * math.pi / 4,
                  child: Icon(
                    isOpen ? Icons.close : Icons.add,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final List<Widget> items = [];
    const double radius = 80;
    const double startAngle = math.pi; // Start from left
    const double sweepAngle = math.pi / 2; // Sweep 90 degrees

    for (int i = 0; i < _menuItems.length; i++) {
      final item = _menuItems[i];
      final angle = startAngle + (sweepAngle / (_menuItems.length - 1)) * i;

      items.add(
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final x = math.cos(angle) * radius * _expandAnimation.value;
            final y = math.sin(angle) * radius * _expandAnimation.value;

            return Positioned(
              right: 8 - x,
              bottom: 8 - y,
              child: Transform.scale(
                scale: _expandAnimation.value,
                child: Opacity(
                  opacity: _expandAnimation.value,
                  child: _buildMenuItem(item),
                ),
              ),
            );
          },
        ),
      );
    }

    return items;
  }

  Widget _buildMenuItem(_FabMenuItem item) {
    return Tooltip(
      message: item.label,
      child: FloatingActionButton.small(
        heroTag: item.label,
        backgroundColor: item.color,
        foregroundColor: Colors.white,
        onPressed: () => _handleAction(item.action),
        child: Icon(item.icon),
      ),
    );
  }
}

enum FabAction {
  textChat,
  voice,
  image,
  video,
  email,
}

class _FabMenuItem {
  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.action,
  });

  final IconData icon;
  final String label;
  final Color color;
  final FabAction action;
}
