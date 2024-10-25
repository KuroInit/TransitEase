import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position> getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (await Geolocator.isLocationServiceEnabled()) {
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
    } else {
      throw Exception('Location services are disabled');
    }
  }
}
