import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/config.dart';
import 'core/utils/permission_helper.dart';
import 'features/auth/auth.dart';
import 'features/chat/chat.dart';
import 'features/navigation/navigation.dart';
import 'features/settings/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment configuration
  await EnvLoader.load();
  
  runApp(
    const ProviderScope(
      child: MultimodalAIAssistantApp(),
    ),
  );
}

class MultimodalAIAssistantApp extends ConsumerWidget {
  const MultimodalAIAssistantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsNotifierProvider);

    return MaterialApp(
      title: 'Multimodal AI Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settingsState.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      // Named routes for deep linking
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainShell(),
        '/chat': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      // Handle deep links for conversations
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        
        // Handle /conversation/:id deep links
        if (uri.pathSegments.length == 2 && 
            uri.pathSegments[0] == 'conversation') {
          final conversationId = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversationId),
          );
        }
        
        return null;
      },
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper that shows appropriate screen based on auth state
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _permissionsChecked = false;
  bool _showPermissionScreen = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequestedPermissions = prefs.getBool('permissions_requested') ?? false;
    
    if (!hasRequestedPermissions) {
      // First launch - show permission screen
      setState(() {
        _showPermissionScreen = true;
        _permissionsChecked = true;
      });
    } else {
      setState(() {
        _permissionsChecked = true;
      });
    }
  }

  Future<void> _onPermissionsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested', true);
    setState(() {
      _showPermissionScreen = false;
    });
  }

  Future<void> _onSkipPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested', true);
    setState(() {
      _showPermissionScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking permissions
    if (!_permissionsChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show permission request screen on first launch
    if (_showPermissionScreen) {
      return PermissionRequestScreen(
        onPermissionsGranted: _onPermissionsGranted,
        onSkip: _onSkipPermissions,
      );
    }

    final authState = ref.watch(authNotifierProvider);

    // Show loading while checking auth status
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show main shell if authenticated, otherwise show onboarding
    if (authState.isAuthenticated) {
      return const MainShell();
    }

    return const OnboardingScreen();
  }
}
