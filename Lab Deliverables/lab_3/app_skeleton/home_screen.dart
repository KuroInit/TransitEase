import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:transitease/models/models.dart';
import 'bug_report_form.dart';
import 'preferences_menu.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng _userLocation = LatLng(51.509364, -0.128928);
  bool _locationLoaded = false;
  String _authStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _trackingPermission();
  }

  Future<void> _trackingPermission() async {
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    setState(() => _authStatus = '$status');
    if (status == TrackingStatus.notDetermined) {
      final TrackingStatus status =
          await AppTrackingTransparency.requestTrackingAuthorization();
      setState(() => _authStatus = '$status');
    } else if (AppTrackingTransparency.trackingAuthorizationStatus == Null) {
      openAppSettings();
    }
  }

  Future<void> _getUserLocation() async {
    var status = await Geolocator.checkPermission();
    if (status == Geolocator.isLocationServiceEnabled()) {
      setState(() {
        _locationLoaded = true;
      });
    } else {
      status = await Geolocator.requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: Drawer(
        child: BugReportFormUI(user: widget.user),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
            ],
          ),
          Positioned(
            top: 80,
            left: 20,
            child: SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 5,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => PreferencesMenu(),
                  );
                },
                child: Icon(Icons.settings, color: Colors.black, size: 24),
                shape: CircleBorder(),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: SizedBox(
              width: 45,
              height: 45,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                elevation: 5,
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Icon(Icons.bug_report, color: Colors.black, size: 24),
                shape: CircleBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
