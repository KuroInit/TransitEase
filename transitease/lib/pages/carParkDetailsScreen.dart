import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:transitease/models/models.dart';

class CarParkDetailScreen extends StatefulWidget {
  final String carParkId;
  final LatLng carParkLocation;
  final Preferences vehPref;

  CarParkDetailScreen({
    required this.carParkLocation,
    required this.carParkId,
    required this.vehPref,
  });

  @override
  _CarParkDetailScreenState createState() => _CarParkDetailScreenState();
}

class _CarParkDetailScreenState extends State<CarParkDetailScreen> {
  final MapController _mapController = MapController();
  bool isCarSelected = true;
  DateTime? selectedStartTime;
  DateTime? selectedEndTime;
  String? calculatedPrice;
  List<dynamic>? carTimeSlots;
  List<dynamic>? motorcycleTimeSlots;

  @override
  void initState() {
    super.initState();
    isCarSelected = widget.vehPref.vehicleType == VehicleType.car;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Park Details'),
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.carParkLocation,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.transitease',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: widget.carParkLocation,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('car_parks')
                  .doc(widget.carParkId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading car park details.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var data = snapshot.data?.data();
                if (data == null) {
                  return Center(child: Text('No car park data found.'));
                }

                var carParkData = Map<String, dynamic>.from(data as Map);
                var carPark =
                    Map<String, dynamic>.from(carParkData['carpark'] as Map);
                var vehCat = carPark['vehCat'] as Map<String, dynamic>?;

                carTimeSlots = vehCat?['Car']?['timeSlots'] as List<dynamic>?;
                motorcycleTimeSlots =
                    vehCat?['Motorcycle']?['timeSlots'] as List<dynamic>?;
                print(widget.carParkId);

                var selectedTimeSlots =
                    isCarSelected ? carTimeSlots : motorcycleTimeSlots;

                return Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Text(
                        carPark['ppName'] ?? 'Unnamed Car Park',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text('Car'),
                            selected: isCarSelected,
                            onSelected: (selected) {
                              setState(() {
                                isCarSelected = true;
                                calculatedPrice = null;
                              });
                            },
                          ),
                          SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Motorcycle'),
                            selected: !isCarSelected,
                            onSelected: (selected) {
                              setState(() {
                                isCarSelected = false;
                                calculatedPrice = null;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Car Park Pricing Calculator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          ElevatedButton(
                            onPressed: () => _selectDateTime(context, true),
                            child: Text(
                              selectedStartTime == null
                                  ? 'Select Start Time'
                                  : DateFormat('yyyy-MM-dd HH:mm')
                                      .format(selectedStartTime!),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'End Time',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          ElevatedButton(
                            onPressed: () => _selectDateTime(context, false),
                            child: Text(
                              selectedEndTime == null
                                  ? 'Select End Time'
                                  : DateFormat('yyyy-MM-dd HH:mm')
                                      .format(selectedEndTime!),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: selectedTimeSlots == null ||
                                selectedTimeSlots.isEmpty
                            ? null
                            : () => _calculatePrice(selectedTimeSlots!),
                        child: Text('Calculate Price'),
                      ),
                      SizedBox(height: 10),
                      if (calculatedPrice != null)
                        Text(
                          'Estimated Cost: $calculatedPrice',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    DateTime initialDate = isStart
        ? (selectedStartTime ?? DateTime.now())
        : (selectedEndTime ?? DateTime.now());

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      TimeOfDay initialTime = isStart
          ? TimeOfDay.fromDateTime(selectedStartTime ?? DateTime.now())
          : TimeOfDay.fromDateTime(selectedEndTime ?? DateTime.now());

      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStart) {
            selectedStartTime = fullDateTime;
            if (selectedEndTime != null &&
                selectedEndTime!.isBefore(selectedStartTime!)) {
              selectedEndTime = null;
            }
          } else {
            selectedEndTime = fullDateTime;
          }
          calculatedPrice = null;
        });
      }
    }
  }

  void _calculatePrice(List<dynamic> timeSlots) {
    if (selectedStartTime == null || selectedEndTime == null) {
      setState(() {
        calculatedPrice = 'Please select both start and end times.';
      });
      return;
    }

    DateTime start = selectedStartTime!;
    DateTime end = selectedEndTime!;

    if (end.isBefore(start)) {
      setState(() {
        calculatedPrice = 'End time must be after start time.';
      });
      return;
    }

    double totalCost = 0.0;

    DateTime current = start;
    while (current.isBefore(end)) {
      DateTime nextDay = DateTime(
        current.year,
        current.month,
        current.day + 1,
      );

      DateTime periodEnd = nextDay.isBefore(end) ? nextDay : end;

      bool isSaturday = current.weekday == DateTime.saturday;
      bool isSundayOrPH = current.weekday == DateTime.sunday;

      double dayCost = _calculateCostForDay(
          current, periodEnd, timeSlots, isSaturday, isSundayOrPH);
      totalCost += dayCost;

      current = nextDay;
    }

    setState(() {
      calculatedPrice = '\$${totalCost.toStringAsFixed(2)}';
    });
  }

  double _calculateCostForDay(DateTime dayStart, DateTime dayEnd,
      List<dynamic> timeSlots, bool isSaturday, bool isSundayOrPH) {
    double dayCost = 0.0;

    for (var slot in timeSlots) {
      var slotMap = Map<String, dynamic>.from(slot);

      DateTime slotStart = _parseSlotTime(dayStart, slotMap['startTime']);
      DateTime slotEnd = _parseSlotTime(dayStart, slotMap['endTime']);

      if (slotEnd.isBefore(slotStart)) {
        slotEnd = slotEnd.add(Duration(days: 1));
      }

      DateTime overlapStart =
          dayStart.isAfter(slotStart) ? dayStart : slotStart;
      DateTime overlapEnd = dayEnd.isBefore(slotEnd) ? dayEnd : slotEnd;

      if (overlapEnd.isAfter(overlapStart)) {
        Duration overlapDuration = overlapEnd.difference(overlapStart);

        String rateKey = isSundayOrPH
            ? 'sunPHRate'
            : (isSaturday ? 'satdayRate' : 'weekdayRate');

        double ratePerHour = _parseRate(slotMap[rateKey]);

        if (ratePerHour == 0) {
          continue;
        }

        double hours = overlapDuration.inMinutes / 60;
        double cost = hours * ratePerHour;

        dayCost += cost;
      }
    }

    return dayCost;
  }

  DateTime _parseSlotTime(DateTime day, String timeString) {
    try {
      DateFormat formatter = DateFormat('hh.mm a');
      DateTime time = formatter.parse(timeString);

      return DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
    } catch (e) {
      return day;
    }
  }

  double _parseRate(String? rateString) {
    if (rateString == null) return 0.0;
    String sanitized = rateString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(sanitized) ?? 0.0;
  }
}
