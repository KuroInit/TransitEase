import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:hive/hive.dart';
import 'package:transitease/models/models.dart';
import 'bugReportForm.dart';
import 'preferencesMenu.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginScreen.dart';
import 'geohashQuery.dart';
import 'mapMarkers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:async';
import 'package:dart_geohash/dart_geohash.dart';
import 'carParkDetails.dart';
import 'carParkDetailsScreen.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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

  // ItemScrollController for scrolling to list items
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // Timestamp for the list view data
  DateTime? _listViewDataFetchedTime;

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
        'name': carParkData['ppName'] ?? 'Unnamed Car Park',
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

          double distance = haversineDistance(
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

          double distanceA = haversineDistance(
            _userLocation.latitude,
            _userLocation.longitude,
            latA,
            lonA,
          );
          double distanceB = haversineDistance(
            _userLocation.latitude,
            _userLocation.longitude,
            latB,
            lonB,
          );

          return distanceA.compareTo(distanceB);
        });

        setState(() {
          sortedCarParks = carParksWithinRadius;
          _listViewDataFetchedTime = DateTime.now(); // Update the timestamp
        });
      } catch (e) {
        print("Error while sorting car parks: $e");
      }
    } else {
      print("Location not loaded yet.");
    }
  }

  void _updateMarkers() async {
    List<DocumentSnapshot> nearbyCarParks = await queryGeohashesWithinRadius(
      _userLocation.latitude,
      _userLocation.longitude,
      _preferences.radiusDistance,
    );

    List<Map<String, dynamic>> newCarParks = nearbyCarParks.map((doc) {
      var carParkData = doc['carpark'];
      return {
        'id': doc.id,
        'geohash': carParkData['geohash'],
        'name': carParkData['ppName'] ?? 'Unnamed Car Park',
      };
    }).toList();

    newCarParks.sort((a, b) => a['id'].compareTo(b['id']));

    if (!_areCarParksEqual(newCarParks, sortedCarParks)) {
      setState(() {
        sortedCarParks = newCarParks;
        markers = generateMarkersWithOnTap(nearbyCarParks, _onMarkerTap);
        _listViewDataFetchedTime = DateTime.now(); // Update the timestamp
      });
    }
  }

  bool _areCarParksEqual(
      List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] ||
          list1[i]['geohash'] != list2[i]['geohash']) {
        return false;
      }
    }
    return true;
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
        distanceFilter: 500,
      ),
    ).listen((Position position) {
      double distance = haversineDistance(
        _userLocation.latitude,
        _userLocation.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance >= 0.5) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _locationLoaded = true;
          _mapController.move(_userLocation, _currentZoom);
          _updateMarkers();
        });
      }
    });
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

  void _recenterMap() {
    if (_locationLoaded) {
      _mapController.move(_userLocation, _currentZoom);
    }
  }

  void _onMarkerTap(String carParkId) {
    // Find the index of the car park in the sorted list
    int index =
        sortedCarParks.indexWhere((carPark) => carPark['id'] == carParkId);

    if (index != -1) {
      GeoHasher geohash = GeoHasher();
      var decodedLocation = geohash.decode(sortedCarParks[index]['geohash']);
      LatLng carParkLocation = LatLng(decodedLocation[1], decodedLocation[0]);

      // Scroll to the corresponding item and open details screen
      _navigateToCarParkDetails(carParkId, carParkLocation, index);
    }
  }

  void _navigateToCarParkDetails(
      String carParkId, LatLng carParkLocation, int index) {
    // Navigate to the details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CarParkDetailScreen(
          carParkId: carParkId,
          carParkLocation: carParkLocation,
          vehPref: _preferences,
        ),
      ),
    );

    // Optionally, center the map on the car park
    _mapController.move(carParkLocation, 18.0);

    // Scroll to the item in the list
    _itemScrollController.scrollTo(
      index: index,
      duration: Duration(milliseconds: 500),
      alignment: 0.5, // Center the item in the list
    );
  }

  Future<void> _refreshListView() async {
    // Implement any data fetching or refreshing logic here
    _updateMarkers();
    setState(() {
      _listViewDataFetchedTime = DateTime.now();
    });
  }

  String _formatTimeDifference(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Data updated just now';
    } else if (difference.inMinutes < 60) {
      return 'Data updated ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Data updated ${difference.inHours} hours ago';
    } else {
      return 'Data updated ${difference.inDays} days ago';
    }
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
                userAgentPackageName: 'com.example.transitease',
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.green,
                  ),
                  markerSize: Size(25, 25),
                  accuracyCircleColor: Colors.green.withOpacity(0.2),
                  headingSectorRadius: 6.5,
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
                  Divider(height: 1, thickness: 1, color: Colors.grey),
                  IconButton(
                    icon: Icon(Icons.my_location, color: Colors.green),
                    onPressed: _recenterMap,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 10,
            right: 10,
            child: Container(
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _listViewDataFetchedTime != null
                              ? _formatTimeDifference(_listViewDataFetchedTime!)
                              : 'Data not loaded',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.green),
                          onPressed: _refreshListView,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: sortedCarParks.isEmpty
                        ? Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0),
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
                        : ScrollablePositionedList.builder(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            scrollDirection: Axis.horizontal,
                            itemCount: sortedCarParks.length,
                            itemBuilder: (context, index) {
                              String carParkId = sortedCarParks[index]['id'];
                              String carParkGeohash =
                                  sortedCarParks[index]['geohash'];
                              String carParkName = sortedCarParks[index]
                                      ['name'] ??
                                  'Unknown Car Park';

                              // Decode the geohash to get latitude and longitude
                              GeoHasher geohash = GeoHasher();
                              var decodedLocation =
                                  geohash.decode(carParkGeohash);
                              LatLng carParkLocation = LatLng(
                                  decodedLocation[1], decodedLocation[0]);

                              return GestureDetector(
                                onTap: () => _navigateToCarParkDetails(
                                    carParkId, carParkLocation, index),
                                child: Container(
                                  width: 210,
                                  height: 100,
                                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.all(10),
                                  child: CarParkDetails(carParkId: carParkId),
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
