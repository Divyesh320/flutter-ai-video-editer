import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_ai_assistant/features/auth/auth.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('displays app title and buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      expect(find.text('Multimodal AI Assistant'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });

    testWidgets('navigates to signup on Get Started tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('navigates to login on existing account tap', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.tap(find.text('I already have an account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('LoginScreen', () {
    testWidgets('displays email and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays OAuth buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      // Initially password is obscured - find visibility icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now should show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('has login button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('SignupScreen', () {
    testWidgets('displays all required fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Name (optional)'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('displays OAuth buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
    });

    testWidgets('shows password requirements helper text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pump();

      expect(
        find.text('Min 8 characters, with letter and number'),
        findsOneWidget,
      );
    });

    testWidgets('has create account button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('has 4 text form fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SignupScreen()),
        ),
      );
      await tester.pump();

      // Name, Email, Password, Confirm Password
      expect(find.byType(TextFormField), findsNWidgets(4));
    });
  });
}
