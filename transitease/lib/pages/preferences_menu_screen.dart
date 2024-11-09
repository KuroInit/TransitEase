import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:transitease/models/models.dart';

class PreferencesMenu extends StatefulWidget {
  final Preferences currentPreferences;
  final AppUser user;
  PreferencesMenu({required this.currentPreferences, required this.user});

  @override
  _PreferencesMenuState createState() => _PreferencesMenuState();
}

class _PreferencesMenuState extends State<PreferencesMenu> {
  late int _selectedTens;
  late int _selectedOnes;
  late int _selectedMeter;
  late VehicleType _selectedVehicleType;

  List<int> tens = List.generate(10, (index) => index);
  List<int> ones = List.generate(10, (index) => index);
  List<int> meters = [0, 5];

  @override
  void initState() {
    super.initState();
    _initializePickerValues();
  }

  void _initializePickerValues() {
    int radiusInKm = (widget.currentPreferences.radiusDistance / 1000).ceil();

    _selectedTens = radiusInKm ~/ 10;
    _selectedOnes = radiusInKm % 10;
    _selectedMeter =
        (widget.currentPreferences.radiusDistance % 1000) > 0 ? 5 : 0;

    _selectedVehicleType = widget.currentPreferences.vehicleType;
  }

  Future<void> _savePreferences() async {
    int kilometerValue = (_selectedTens * 10) + _selectedOnes;
    int radius = _selectedMeter == 5 ? kilometerValue + 1 : kilometerValue;

    Preferences preferences = Preferences(
      radiusDistance: radius * 1000,
      vehicleType: _selectedVehicleType,
    );

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('user_preferences')
            .doc(widget.user.userID)
            .set({
          'radiusDistance': preferences.radiusDistance,
          'preferredVehicle':
              preferences.vehicleType.toString().split('.').last,
        });

        Navigator.pop(context, preferences);
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e) {
      print('Failed to save preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Set Preferences',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 150,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController:
                      FixedExtentScrollController(initialItem: _selectedTens),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedTens = tens[index];
                    });
                  },
                  children: tens
                      .map((digit) => Text(digit.toString().padLeft(1, '0')))
                      .toList(),
                ),
              ),
              SizedBox(
                width: 50,
                height: 150,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController:
                      FixedExtentScrollController(initialItem: _selectedOnes),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedOnes = ones[index];
                    });
                  },
                  children: ones
                      .map((digit) => Text(digit.toString().padLeft(1, '0')))
                      .toList(),
                ),
              ),
              Text('.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(
                width: 50,
                height: 150,
                child: CupertinoPicker(
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                      initialItem: meters.indexOf(_selectedMeter)),
                  onSelectedItemChanged: (int index) {
                    setState(() {
                      _selectedMeter = meters[index];
                    });
                  },
                  children: meters.map((m) => Text(m.toString())).toList(),
                ),
              ),
              Text(' km',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.directions_car, color: Colors.blue),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType =
                        _selectedVehicleType == VehicleType.car
                            ? VehicleType.bike
                            : VehicleType.car;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _selectedVehicleType == VehicleType.car
                        ? Colors.blue
                        : Colors.green,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: Duration(milliseconds: 300),
                        alignment: _selectedVehicleType == VehicleType.car
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Transform.scale(
                          scale: 1.5,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.motorcycle, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _savePreferences,
            child: Text('Save Preferences'),
          ),
        ],
      ),
    );
  }
}
