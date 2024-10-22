import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

class AppUser {
  final String userID;
  final String authToken;
  bool notificationEnabled;

  AppUser(
      {required this.userID,
      required this.authToken,
      this.notificationEnabled = false});

  factory AppUser.fromFirebaseUser(User firebaseUser, String? authToken) {
    return AppUser(
      userID: firebaseUser.email ?? '', // Use empty string if email is null
      authToken: authToken ?? '', // Use empty string if authToken is null
    );
  }
}

class Notification {
  final String notificationID;
  final String notificationType;
  final String message;

  Notification({
    required this.notificationID,
    required this.notificationType,
    required this.message,
  });
}

class Carpark {
  final String carparkID;
  final String name;
  final LatLng locationCoordinates;
  final int capacity;
  final int currentOccupancy;
  final double pricePerHour;
  final bool realTimeAvailability;

  Carpark({
    required this.carparkID,
    required this.name,
    required this.locationCoordinates,
    required this.capacity,
    required this.currentOccupancy,
    required this.pricePerHour,
    required this.realTimeAvailability,
  });
}

enum Severity {
  low,
  medium,
  high,
}

class BugReport {
  final String bugReportID;
  final AppUser userID;
  final String description;
  final Severity severity;

  BugReport({
    required this.bugReportID,
    required this.userID,
    required this.description,
    required this.severity,
  });
}

enum VehicleType {
  car,
  bike,
}

class Preferences {
  final int radiusDistance;
  final VehicleType vehicleType;

  Preferences({
    required this.radiusDistance,
    required this.vehicleType,
  });
}
