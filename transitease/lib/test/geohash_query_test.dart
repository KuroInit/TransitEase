import 'package:flutter_test/flutter_test.dart';
import 'package:transitease/services/geohash_query.dart';

void main() {
  group('calculateGeohashRange', () {
    test('returns a geohash range based on latitude, longitude, and radius',
        () {
      double latitude = 1.3521;
      double longitude = 103.8198;
      int radius = 500;

      List<String> geohashRange =
          calculateGeohashRange(latitude, longitude, radius);

      expect(geohashRange, isA<List<String>>());
      expect(geohashRange.length, 2);
      expect(geohashRange[0], isNotEmpty);
      expect(geohashRange[1], isNotEmpty);
    });
  });

  group('haversineDistance', () {
    test('calculates correct distance between two lat/lon points', () {
      double lat1 = 1.3521;
      double lon1 = 103.8198;
      double lat2 = 1.3525;
      double lon2 = 103.8202;

      double distance = haversineDistance(lat1, lon1, lat2, lon2);

      expect(distance, closeTo(56, 10));
    });

    test('returns zero when calculating distance between identical points', () {
      double lat1 = 1.3521;
      double lon1 = 103.8198;

      double distance = haversineDistance(lat1, lon1, lat1, lon1);

      expect(distance, equals(0));
    });
  });
}
