import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transitease/pages/sign_up_screen.dart';

//TODO: FIX UNIT TEST
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUserCredential = MockUserCredential();
  });

  group('SignUpScreen Widget Tests', () {
    testWidgets('displays all required fields and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Verify presence of email, password, and confirm password fields
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Verify presence of sign-up and back-to-login buttons
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('password validation checklist updates based on input',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Enter a password that doesn't meet requirements
      await tester.enterText(find.byType(TextField).at(1), 'short');
      await tester.pump();

      // Verify checklist items update accordingly
      expect(find.text('Contains uppercase letter'), findsOneWidget);
      expect(find.byIcon(Icons.close),
          findsNWidgets(4)); // All items should initially be invalid

      // Update password with valid complexity
      await tester.enterText(find.byType(TextField).at(1), 'Password@123');
      await tester.pump();

      // Check that checklist items are marked valid
      expect(find.byIcon(Icons.check),
          findsNWidgets(4)); // All checklist items valid
    });

    testWidgets('shows error when passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Enter mismatched passwords
      await tester.enterText(find.byType(TextField).at(1), 'Password@123');
      await tester.enterText(find.byType(TextField).at(2), 'DifferentPassword');
      await tester.pump();

      // Verify password match validation fails
      expect(find.byIcon(Icons.close),
          findsOneWidget); // 'Passwords match' should be invalid
    });

    testWidgets('displays notification for password requirements on sign up',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Enter an invalid password and attempt to sign up
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.enterText(find.byType(TextField).at(2), 'password');
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      // Verify notification message for password requirements
      expect(find.text('Password does not meet complexity requirements'),
          findsOneWidget);
    });

    testWidgets('successful sign up displays success notification',
        (WidgetTester tester) async {
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'email',
        password: 'password',
      )).thenAnswer((_) async => mockUserCredential);

      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Enter valid email and password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password@123');
      await tester.enterText(find.byType(TextField).at(2), 'Password@123');

      // Attempt to sign up
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      // Verify success notification
      expect(find.text('Sign up successful! Please log in.'), findsOneWidget);
    });

    testWidgets('sign up failure shows error notification',
        (WidgetTester tester) async {
      // Mock sign up failure
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'email',
        password: 'password',
      )).thenThrow(FirebaseAuthException(
          message: 'An error occurred', code: 'auth/failure'));

      await tester.pumpWidget(MaterialApp(home: SignUpScreen()));

      // Enter valid email and password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Password@123');
      await tester.enterText(find.byType(TextField).at(2), 'Password@123');

      // Attempt to sign up
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      // Verify error notification
      expect(find.text('Sign up failed: An error occurred'), findsOneWidget);
    });
  });
}
