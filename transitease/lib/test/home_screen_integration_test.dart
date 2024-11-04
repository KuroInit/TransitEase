import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:transitease/models/models.dart';
import 'package:transitease/pages/home_screen.dart';

//TODO: FIX INTEGRATION TEST

// Mock FirebaseAuth class
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// Mock Firebase User class with a non-null uid
class MockUser extends Mock implements User {
  @override
  String get uid => 'test_uid';
}

class MockAppUser extends Mock implements AppUser {
  @override
  String get appUserUid => 'test_uid';
}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockAppUser mockAppuser;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    // Initialize mocks and fake Firestore
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockAppuser = MockAppUser();
    fakeFirestore = FakeFirebaseFirestore();

    // Mock FirebaseAuth's currentUser to return mockUser
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);

    // Add test data to Firestore
    fakeFirestore.collection('car_parks').doc('1').set({
      'carpark': {
        'ppName': 'Test Car Park 1',
        'geohash': 'w21z5e1u',
      }
    });
    fakeFirestore.collection('car_parks').doc('2').set({
      'carpark': {
        'ppName': 'Test Car Park 2',
        'geohash': 'w21z5e2v',
      }
    });
  });

  testWidgets('HomeScreen displays car parks and handles user interaction',
      (WidgetTester tester) async {
    // Build the HomeScreen widget
    await tester.pumpWidget(MaterialApp(
      home: HomeScreen(
        user: mockAppuser, // Pass mockUser directly
        firestore: fakeFirestore,
        firebaseAuth: mockFirebaseAuth,
      ),
    ));

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that the map is displayed
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify that the list of car parks is displayed
    expect(find.text('Test Car Park 1'), findsOneWidget);
    expect(find.text('Test Car Park 2'), findsOneWidget);

    // Tap on a car park to navigate to details
    await tester.tap(find.text('Test Car Park 1'));
    await tester.pumpAndSettle();

    // Since CarParkDetailScreen is a new route, check if it's displayed
    expect(find.text('Car Park Details'), findsOneWidget);
  });
}
