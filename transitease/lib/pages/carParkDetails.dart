import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:transitease/models/models.dart';

class CarParkDetails extends StatefulWidget {
  final String carParkId;

  const CarParkDetails({Key? key, required this.carParkId}) : super(key: key);

  @override
  _CarParkDetailsState createState() => _CarParkDetailsState();
}

class _CarParkDetailsState extends State<CarParkDetails> {
  Carpark? carParkData;
  bool isLoading = true;
  int? carLotsAvailable;
  int? motorcycleLotsAvailable;

  @override
  void initState() {
    super.initState();
    _fetchCarParkDetails();
  }

  Future<void> _fetchCarParkDetails() async {
    print("Fetching data for carParkId: ${widget.carParkId}");

    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('car_parks')
          .doc(widget.carParkId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;

        setState(() {
          carParkData = _carparkFromFirestore(snapshot);

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

  Carpark _carparkFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    var carparkData = data?['carpark'] as Map<String, dynamic>?;
    if (carparkData == null) {
      return Carpark(
        carparkID: 'Unavailable',
        name: 'Unavailable',
        locationCoordinates: LatLng(0, 0),
        capacity: 0,
        currentOccupancy: 0,
        pricePerHour: 0.0,
        realTimeAvailability: false,
      );
    }

    List<dynamic>? coordinates =
        carparkData['geometries']?['coordinates'] as List<dynamic>?;

    return Carpark(
      carparkID: carparkData['ppCode'] ?? 'Unavailable',
      name: carparkData['ppName'] ?? 'Unavailable',
      locationCoordinates: coordinates != null && coordinates.length == 2
          ? LatLng(coordinates[1], coordinates[0])
          : LatLng(0, 0),
      capacity: carparkData['vehCat']?['Car']?['parkCapacity'] ?? 0,
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
        ? "$carLotsAvailable/${carParkData!.capacity}"
        : "${carParkData!.capacity}";

    Color motorcycleIconColor =
        motorcycleLotsAvailable != null ? Colors.green : Colors.red;
    String motorcycleLotText = motorcycleLotsAvailable != null
        ? "$motorcycleLotsAvailable/${carParkData!.capacity}"
        : "${carParkData!.capacity}";

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Container(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: AutoSizeText(
                carParkData!.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.blueAccent,
                ),
                maxLines: 2,
                minFontSize: 12,
                maxFontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 12),
            Spacer(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLotInfoBox(
                    icon: Icons.directions_car,
                    iconColor: carIconColor,
                    lotText: carLotText,
                    label: "Car Lots",
                    availabilityIcon: carLotsAvailable != null
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    availabilityColor: carIconColor,
                  ),
                  _buildLotInfoBox(
                    icon: Icons.motorcycle,
                    iconColor: motorcycleIconColor,
                    lotText: motorcycleLotText,
                    label: "Motorcycle Lots",
                    availabilityIcon: motorcycleLotsAvailable != null
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    availabilityColor: motorcycleIconColor,
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildLotInfoBox({
    required IconData icon,
    required Color iconColor,
    required String lotText,
    required String label,
    required IconData availabilityIcon,
    required Color availabilityColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: iconColor),
          SizedBox(height: 8),
          Text(
            lotText,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 4),
          SizedBox(height: 8),
          Icon(
            availabilityIcon,
            color: availabilityColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
