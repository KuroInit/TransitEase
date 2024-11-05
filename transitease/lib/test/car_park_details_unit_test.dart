import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:transitease/models/models.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
  });

  group('Data Parsing and Transformation Tests', () {
    test(
        'carparkFromFirestore creates correct Carpark object with complete data',
        () async {
      final mockData = {
        'carpark': {
          'ppCode': 'TEST01',
          'ppName': 'Test Carpark',
          'geometries': {
            'coordinates': [103.8198, 1.3521]
          },
          'vehCat': {
            'Car': {'parkCapacity': 100},
            'Motorcycle': {'parkCapacity': 50}
          },
        },
        'availability': {
          'C': {'lotsAvailable': 75},
          'M': {'lotsAvailable': 30}
        },
      };

      await fakeFirestore.collection('car_parks').doc('TEST01').set(mockData);
      final doc =
          await fakeFirestore.collection('car_parks').doc('TEST01').get();

      final carpark = carparkFromFirestore(doc);

      expect(carpark.carparkID, equals('TEST01'));
      expect(carpark.name, equals('Test Carpark'));
      expect(carpark.locationCoordinates.latitude, equals(1.3521));
      expect(carpark.locationCoordinates.longitude, equals(103.8198));
      expect(carpark.carCapacity, equals(100));
      expect(carpark.bikeCapacity, equals(50));
      expect(carpark.realTimeAvailability, isTrue);

      print('Test for carparkFromFirestore with complete data passed.');
    });

    test('carparkFromFirestore handles missing coordinates correctly',
        () async {
      final mockData = {
        'carpark': {
          'ppCode': 'TEST01',
          'ppName': 'Test Carpark',
          'geometries': {},
          'vehCat': {
            'Car': {'parkCapacity': 100},
            'Motorcycle': {'parkCapacity': 50}
          },
        },
      };

      await fakeFirestore.collection('car_parks').doc('TEST01').set(mockData);
      final doc =
          await fakeFirestore.collection('car_parks').doc('TEST01').get();

      final carpark = carparkFromFirestore(doc);

      expect(carpark.locationCoordinates, equals(LatLng(0, 0)));

      print('Test for carparkFromFirestore with missing coordinates passed.');
    });

    test('carparkFromFirestore handles malformed coordinates as null correctly',
        () async {
      final mockData = {
        'carpark': {
          'ppCode': 'TEST01',
          'ppName': 'Test Carpark',
          'geometries': {
            'coordinates': [null, null]
          },
          'vehCat': {
            'Car': {'parkCapacity': 100},
            'Motorcycle': {'parkCapacity': 50}
          },
        },
      };

      await fakeFirestore.collection('car_parks').doc('TEST01').set(mockData);
      final doc =
          await fakeFirestore.collection('car_parks').doc('TEST01').get();

      final carpark = carparkFromFirestore(doc);

      expect(carpark.locationCoordinates, equals(LatLng(0, 0)));

      print('Test for carparkFromFirestore with malformed coordinates passed.');
    });

    test('carparkFromFirestore handles malformed vehicle categories correctly',
        () async {
      final mockData = {
        'carpark': {
          'ppCode': 'TEST01',
          'ppName': 'Test Carpark',
          'geometries': {
            'coordinates': [103.8198, 1.3521]
          },
          'vehCat': {'Car': 'invalid', 'Motorcycle': 'invalid'},
        },
      };

      await fakeFirestore.collection('car_parks').doc('TEST01').set(mockData);
      final doc =
          await fakeFirestore.collection('car_parks').doc('TEST01').get();

      final carpark = carparkFromFirestore(doc);

      expect(carpark.carCapacity, equals(0));
      expect(carpark.bikeCapacity, equals(0));

      print(
          'Test for carparkFromFirestore with malformed vehicle categories passed.');
    });
  });
}

Carpark carparkFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>?;
  final carparkData = data?['carpark'] as Map<String, dynamic>?;

  if (carparkData == null) {
    return Carpark(
      carparkID: 'Unavailable',
      name: 'Unavailable',
      locationCoordinates: LatLng(0, 0),
      carCapacity: 0,
      bikeCapacity: 0,
      currentOccupancy: 0,
      pricePerHour: 0.0,
      realTimeAvailability: false,
    );
  }

  List<dynamic>? coordinates =
      carparkData['geometries']?['coordinates'] as List<dynamic>?;

  double latitude = 0;
  double longitude = 0;
  if (coordinates != null && coordinates.length == 2) {
    latitude = coordinates[1] is num ? (coordinates[1] as num).toDouble() : 0;
    longitude = coordinates[0] is num ? (coordinates[0] as num).toDouble() : 0;
  }

  int carCapacity = 0;
  int motorcycleCapacity = 0;

  try {
    final carData = carparkData['vehCat']?['Car'] as Map<String, dynamic>?;
    if (carData != null && carData['parkCapacity'] is int) {
      carCapacity = carData['parkCapacity'] as int;
    }

    final motorcycleData =
        carparkData['vehCat']?['Motorcycle'] as Map<String, dynamic>?;
    if (motorcycleData != null && motorcycleData['parkCapacity'] is int) {
      motorcycleCapacity = motorcycleData['parkCapacity'] as int;
    }
  } catch (e) {}

  return Carpark(
    carparkID: carparkData['ppCode'] ?? 'Unavailable',
    name: carparkData['ppName'] ?? 'Unavailable',
    locationCoordinates: LatLng(latitude, longitude),
    carCapacity: carCapacity,
    bikeCapacity: motorcycleCapacity,
    currentOccupancy: 0,
    pricePerHour: 0.0,
    realTimeAvailability: data?.containsKey('availability') ?? false,
  );
}
