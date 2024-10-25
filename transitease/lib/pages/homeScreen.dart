import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';
import 'package:transitease/models/models.dart';
import 'bugReportForm.dart';
import 'preferencesMenu.dart';
import 'listCarparkScreen.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginScreen.dart';
import 'geohashQuery.dart';
import 'mapMarkers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:async';
import 'dart:math';
import 'package:dart_geohash/dart_geohash.dart';
import 'carParkDetails.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late MapController _mapController;
  LatLng _userLocation = LatLng(51.509364, -0.128928);
  bool _locationLoaded = false;
  double _currentZoom = 15.0;
  List<Marker> markers = [];
  List<Map<String, dynamic>> sortedCarParks = [];
  Box? carParksBox;
  DateTime? lastCheckedTime;
  StreamSubscription<Position>? _positionStreamSubscription;

  Preferences _preferences = Preferences(
    radiusDistance: 1000,
    vehicleType: VehicleType.car,
  );

  Key _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _initializeAppState();
    _startListeningToLocationChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startListeningToLocationChanges();
    }
  }

  Future<void> _initializeAppState() async {
    try {
      await Hive.openBox('carParksBox');
      carParksBox = Hive.box('carParksBox');

      await _checkAuthState();
      await _trackingPermission();

      if (carParksBox != null) {
        await _checkForNewCarParks();
      }

      await _loadCarParks();
    } catch (e) {
      print("Error initializing app state: $e");
    }
  }

  Future<void> _checkForNewCarParks() async {
    if (carParksBox == null) return;

    lastCheckedTime = carParksBox!.get('lastCheckedTime');
    DateTime now = DateTime.now();

    if (lastCheckedTime == null ||
        now.difference(lastCheckedTime!).inHours >= 24) {
      print("Fetching new car parks from Firestore...");
      await _fetchAndSaveCarParksFromFirestore();
    } else {
      print("No need to check Firestore. Last checked: $lastCheckedTime");

      List<Map<String, dynamic>> carParks =
          (carParksBox!.get('carParks') as List)
              .map((carPark) => Map<String, dynamic>.from(carPark))
              .toList();
      _processCarParks(carParks);
    }
  }

  Future<void> _loadCarParks() async {
    if (carParksBox!.isEmpty) {
      await _fetchAndSaveCarParksFromFirestore();
    } else {
      print("Loading car parks from Hive...");

      List<Map<String, dynamic>> carParks =
          (carParksBox!.get('carParks') as List)
              .map((carPark) => Map<String, dynamic>.from(carPark))
              .toList();
      _processCarParks(carParks);
    }
  }

  Future<void> _fetchAndSaveCarParksFromFirestore() async {
    print("Fetching car parks from Firestore...");
    QuerySnapshot carParksSnapshot =
        await FirebaseFirestore.instance.collection('car_parks').get();

    List<Map<String, dynamic>> carParks = carParksSnapshot.docs.map((doc) {
      var carParkData = doc['carpark'];
      return {
        'id': doc.id,
        'geohash': carParkData['geohash'],
      };
    }).toList();

    await carParksBox!.put('carParks', carParks);
    await carParksBox!.put('lastCheckedTime', DateTime.now());
    print("Car parks saved to Hive.");
    _processCarParks(carParks);
  }

  void _processCarParks(List<Map<String, dynamic>> carParks) {
    _sortCarParksByDistanceWithinRadius(carParks);
    _updateMarkers();
  }

  void _sortCarParksByDistanceWithinRadius(
      List<Map<String, dynamic>> carParks) {
    if (_locationLoaded) {
      try {
        List<Map<String, dynamic>> carParksWithinRadius =
            carParks.where((carPark) {
          GeoHasher geohash = GeoHasher();
          var decoded = geohash.decode(carPark['geohash']);

          double lat = decoded[1];
          double lon = decoded[0];

          double distance = _calculateDistance(
            _userLocation.latitude,
            _userLocation.longitude,
            lat,
            lon,
          );

          return distance <= (_preferences.radiusDistance / 1000);
        }).toList();

        carParksWithinRadius.sort((a, b) {
          GeoHasher geohash = GeoHasher();
          var decodedA = geohash.decode(a['geohash']);
          var decodedB = geohash.decode(b['geohash']);

          double latA = decodedA[1];
          double lonA = decodedA[0];
          double latB = decodedB[1];
          double lonB = decodedB[0];

          double distanceA = _calculateDistance(
            _userLocation.latitude,
            _userLocation.longitude,
            latA,
            lonA,
          );
          double distanceB = _calculateDistance(
            _userLocation.latitude,
            _userLocation.longitude,
            latB,
            lonB,
          );

          return distanceA.compareTo(distanceB);
        });

        setState(() {
          sortedCarParks = carParksWithinRadius;
          print("Sorted Car Parks within radius: $sortedCarParks");
        });
      } catch (e) {
        print("Error while sorting car parks: $e");
      }
    } else {
      print("Location not loaded yet.");
    }
  }

  void _startListeningToLocationChanges() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      print("Location services are disabled");
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
        _mapController.move(_userLocation, _currentZoom);
        _updateMarkers();
      });
    });
  }

  void _updateMarkers() async {
    List<DocumentSnapshot> nearbyCarParks = await queryGeohashesWithinRadius(
      _userLocation.latitude,
      _userLocation.longitude,
      _preferences.radiusDistance,
    );

    setState(() {
      List<Map<String, dynamic>> carParks = nearbyCarParks.map((doc) {
        var carParkData = doc['carpark'];
        return {
          'id': doc.id,
          'geohash': carParkData['geohash'],
        };
      }).toList();

      _sortCarParksByDistanceWithinRadius(carParks);
      markers = generateMarkers(nearbyCarParks);
      _mapKey = UniqueKey();
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371;

    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;
    return distance;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _trackingPermission() async {
    final TrackingStatus status =
        await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }

  Future<void> _checkAuthState() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    } else {
      print("User is authenticated: ${user.email}");
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_userLocation, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_userLocation, _currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: Drawer(child: BugReportFormUI(user: widget.user)),
      body: Stack(
        children: [
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _locationLoaded
                  ? _userLocation
                  : LatLng(51.509364, -0.128928),
              initialZoom: _currentZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.always,
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.blue,
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                    ),
                  ),
                  markerSize: Size(80, 80),
                  accuracyCircleColor: Colors.blue.withOpacity(0.2),
                ),
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 150,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6.0)],
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.black),
                    onPressed: _zoomIn,
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey),
                  IconButton(
                    icon: Icon(Icons.remove, color: Colors.black),
                    onPressed: _zoomOut,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            right: 10,
            child: SizedBox(
              height: 300,
              child: sortedCarParks.isEmpty
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(0, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'No car parks in the area',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedCarParks.length,
                      itemBuilder: (context, index) {
                        String carParkId = sortedCarParks[index]['id'];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Container(
                            width: 210,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(0, 187, 6, 6),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CarParkDetails(carParkId: carParkId),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Positioned(
            top: 80,
            left: 20,
            child: FloatingActionButton(
              heroTag: "preferencesDrawer",
              backgroundColor: Colors.white,
              onPressed: () async {
                final result = await showModalBottomSheet<Preferences>(
                  context: context,
                  builder: (context) => PreferencesMenu(
                    currentPreferences: _preferences,
                  ),
                );

                if (result != null) {
                  setState(() {
                    _preferences = result;
                  });

                  _updateMarkers();
                  print(
                      "Updated Preferences: Radius = ${_preferences.radiusDistance}, Vehicle Type = ${_preferences.vehicleType}");
                }
              },
              child: Icon(Icons.settings, color: Colors.black),
            ),
          ),
          Positioned(
            top: 140,
            left: 20,
            child: FloatingActionButton(
              heroTag: "carParkDrawer",
              backgroundColor: Colors.white,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CarParksScreen()));
              },
              child: Icon(Icons.map, color: Colors.black),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: FloatingActionButton(
              heroTag: "bugReport",
              backgroundColor: Colors.white,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: Icon(Icons.bug_report, color: Colors.black),
            ),
          )
        ],
      ),
    );
  }
}
