import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:transitease/models/models.dart';
import 'package:meta/meta.dart';

class CarParkDetails extends StatefulWidget {
  final String carParkId;
  final FirebaseFirestore firestore;

  const CarParkDetails(
      {Key? key, required this.carParkId, required this.firestore})
      : super(key: key);

  @override
  _CarParkDetailsState createState() => _CarParkDetailsState();
}

class _CarParkDetailsState extends State<CarParkDetails> {
  Carpark? carParkData;
  bool isLoading = true;
  int? carLotsAvailable;
  int? motorcycleLotsAvailable;
  int? carCapacity;
  int? motorcycleCapacity;

  @override
  void initState() {
    super.initState();
    fetchCarParkDetails();
  }

  Future<void> fetchCarParkDetails() async {
    print("Fetching data for carParkId: ${widget.carParkId}");

    try {
      DocumentSnapshot snapshot = await widget.firestore
          .collection('car_parks')
          .doc(widget.carParkId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;

        setState(() {
          carParkData = carparkFromFirestore(snapshot);

          if (data != null && data.containsKey('availability')) {
            var availability = data['availability'] as Map<String, dynamic>?;
            carLotsAvailable = availability?['C']?['lotsAvailable'] as int?;
            motorcycleLotsAvailable =
                availability?['M']?['lotsAvailable'] as int?;
          } else {
            print("No availability data for carParkId: ${widget.carParkId}");
          }

          isLoading = false;
        });
      } else {
        print("No document found for carParkId: ${widget.carParkId}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching data for carParkId ${widget.carParkId}: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Carpark carparkFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    var carparkData = data?['carpark'] as Map<String, dynamic>?;

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
      latitude = coordinates[1] is num ? coordinates[1].toDouble() : 0;
      longitude = coordinates[0] is num ? coordinates[0].toDouble() : 0;
    }

    final carCapacity = carparkData['vehCat']?['Car']?['parkCapacity'] ?? 0;
    final motorcycleCapacity =
        carparkData['vehCat']?['Motorcycle']?['parkCapacity'] ?? 0;

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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (carParkData == null) {
      return Center(child: Text("No details available for this car park"));
    }

    Color carIconColor = carLotsAvailable != null ? Colors.green : Colors.red;
    String carLotText = carLotsAvailable != null
        ? "$carLotsAvailable  /  $carCapacity"
        : "$carCapacity";

    Color motorcycleIconColor =
        motorcycleLotsAvailable != null ? Colors.green : Colors.red;
    String motorcycleLotText = motorcycleLotsAvailable != null
        ? "$motorcycleLotsAvailable  /  $motorcycleCapacity"
        : "$motorcycleCapacity";

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            carParkData!.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color.fromARGB(255, 56, 129, 59),
            ),
            maxLines: 1,
            minFontSize: 14,
            maxFontSize: 20,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 25),
          Center(
            child: _buildCompactLotInfoBox(
              carIcon: Icons.directions_car,
              carIconColor: carIconColor,
              carLotText: carLotText,
              carAvailabilityIcon: carLotsAvailable != null
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              carAvailabilityColor: carIconColor,
              motorcycleIcon: Icons.motorcycle,
              motorcycleIconColor: motorcycleIconColor,
              motorcycleLotText: motorcycleLotText,
              motorcycleAvailabilityIcon: motorcycleLotsAvailable != null
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              motorcycleAvailabilityColor: motorcycleIconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLotInfoBox({
    required IconData carIcon,
    required Color carIconColor,
    required String carLotText,
    required IconData carAvailabilityIcon,
    required Color carAvailabilityColor,
    required IconData motorcycleIcon,
    required Color motorcycleIconColor,
    required String motorcycleLotText,
    required IconData motorcycleAvailabilityIcon,
    required Color motorcycleAvailabilityColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(carIcon, size: 30, color: carIconColor),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    carLotText,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 2),
                  Icon(carAvailabilityIcon,
                      color: carAvailabilityColor, size: 18),
                ],
              ),
            ],
          ),
          Divider(thickness: 2, color: Colors.grey[300]),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 10),
              Icon(motorcycleIcon, size: 30, color: motorcycleIconColor),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    motorcycleLotText,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 2),
                  Icon(motorcycleAvailabilityIcon,
                      color: motorcycleAvailabilityColor, size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
