import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Marker> generateMarkers(List<DocumentSnapshot> carParks) {
  return carParks.map((doc) {
    var carparkData = doc['carpark'];

    if (carparkData != null && carparkData['geometries'] != null) {
      List<dynamic> coordinates = carparkData['geometries']['coordinates'];
      double lat = coordinates[1];
      double lon = coordinates[0];

      return Marker(
        point: LatLng(lat, lon),
        child: Icon(Icons.location_on, color: Colors.red),
      );
    } else {
      return Marker(
        point: LatLng(0, 0),
        child: Icon(Icons.error, color: Colors.grey),
      );
    }
  }).toList();
}
