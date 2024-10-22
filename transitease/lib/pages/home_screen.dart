import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _userLocation = LatLng(51.509364, -0.128928); // Default to London
  bool _locationLoaded = false;
  String _authStatus = 'Unknown';
  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _trackingPermission();
  }

  // Function to request permission and get user location
  Future<void> _trackingPermission() async {
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    setState(() => _authStatus = '$status');
    if (status == TrackingStatus.notDetermined) {
      // Request system's tracking authorization dialog
      final TrackingStatus status =
          await AppTrackingTransparency.requestTrackingAuthorization();
      setState(() => _authStatus = '$status');
    } else if (AppTrackingTransparency.trackingAuthorizationStatus == Null) {
      openAppSettings();
      // You could show an alert here to notify the user
    }
  }

  Future<void> _getUserLocation() async {
    var status = await Geolocator.checkPermission();
    if (status == Geolocator.isLocationServiceEnabled()) {
      print("Location enabled");
      _locationLoaded = true;
    } else {
      status = await Geolocator.requestPermission();
      // You could show an alert here to notify the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FlutterMap(
      options: MapOptions(
        initialCenter: _userLocation, // Center the map on the user's location
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
      ],
    ));
  }
}
