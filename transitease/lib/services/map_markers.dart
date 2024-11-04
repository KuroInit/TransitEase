import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

List<Marker> generateMarkersWithOnTap(List<DocumentSnapshot> carParks,
    Function(String) onTap, FirebaseFirestore fire) {
  List<Marker> markers = [];
  for (var doc in carParks) {
    var carParkData = doc['carpark'];
    GeoHasher geohash = GeoHasher();
    var decodedLocation = geohash.decode(carParkData['geohash']);
    LatLng carParkLocation = LatLng(decodedLocation[1], decodedLocation[0]);
    String carParkId = doc.id;

    markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: carParkLocation,
        child: GestureDetector(
          onTap: () {
            onTap(carParkId);
          },
          child: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 25,
          ),
        ),
      ),
    );
  }
  return markers;
}
