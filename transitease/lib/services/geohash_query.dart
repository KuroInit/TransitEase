import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:georange/georange.dart';
import 'dart:math';

List<String> calculateGeohashRange(
    double latitude, double longitude, int radius) {
  final geoRange = GeoRange();
  Range range = geoRange.geohashRange(latitude, longitude, distance: radius);

  print("Geohash Range: Start = ${range.lower}, End = ${range.upper}");

  return [range.lower, range.upper];
}

Future<List<DocumentSnapshot>> queryGeohashesWithinRadius(
    double userLat, double userLon, int radius, FirebaseFirestore fire) async {
  List<String> geohashRange = calculateGeohashRange(userLat, userLon, radius);
  String startGeohash = geohashRange[0];
  String endGeohash = geohashRange[1];

  print("Querying geohashes between: $startGeohash and $endGeohash");

  // Use the injected FirebaseFirestore instance 'fire' instead of FirebaseFirestore.instance
  QuerySnapshot querySnapshot = await fire
      .collection('car_parks')
      .where('carpark.geohash', isGreaterThanOrEqualTo: startGeohash)
      .where('carpark.geohash', isLessThanOrEqualTo: endGeohash)
      .get();

  print("Number of documents found: ${querySnapshot.docs.length}");

  List<DocumentSnapshot> filteredDocuments = querySnapshot.docs.where((doc) {
    try {
      Map<String, dynamic> carparkData = doc['carpark'];

      if (carparkData.containsKey('geometries') &&
          carparkData['geometries'].containsKey('coordinates')) {
        List<dynamic> coordinates = carparkData['geometries']['coordinates'];

        if (coordinates.length == 2) {
          double lat = coordinates[1];
          double lon = coordinates[0];

          double distance = haversineDistance(userLat, userLon, lat, lon);

          return distance <= radius;
        }
      }

      print("Coordinates missing or invalid for document: ${doc.id}");
      return false;
    } catch (e) {
      print("Error processing document: ${doc.id}, Error: $e");
      return false;
    }
  }).toList();

  print("Number of documents within radius: ${filteredDocuments.length}");

  return filteredDocuments;
}

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000;
  final latDistance = _degToRad(lat2 - lat1);
  final lonDistance = _degToRad(lon2 - lon1);
  final a = sin(latDistance / 2) * sin(latDistance / 2) +
      cos(_degToRad(lat1)) *
          cos(_degToRad(lat2)) *
          sin(lonDistance / 2) *
          sin(lonDistance / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _degToRad(double degree) {
  return degree * pi / 180;
}
