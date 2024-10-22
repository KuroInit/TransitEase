import 'package:flutter/material.dart';
import 'package:transitease/models/models.dart';

class PreferencesMenu extends StatefulWidget {
  @override
  _PreferencesMenuState createState() => _PreferencesMenuState();
}

class _PreferencesMenuState extends State<PreferencesMenu> {
  final _radiusController = TextEditingController();
  VehicleType _selectedVehicleType = VehicleType.car;

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  void _savePreferences() {
    int radius = int.parse(_radiusController.text);

    Preferences preferences = Preferences(
      radiusDistance: radius,
      vehicleType: _selectedVehicleType,
    );

    print(
        'Preferences Saved: Radius = ${preferences.radiusDistance}, Vehicle Type = ${preferences.vehicleType}');
    Navigator.pop(context);
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
          TextField(
            controller: _radiusController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Radius Distance (in km)',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          DropdownButton<VehicleType>(
            value: _selectedVehicleType,
            items: VehicleType.values.map((VehicleType type) {
              return DropdownMenuItem<VehicleType>(
                value: type,
                child: Text(type.toString().split('.').last),
              );
            }).toList(),
            onChanged: (VehicleType? newValue) {
              setState(() {
                _selectedVehicleType = newValue!;
              });
            },
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
