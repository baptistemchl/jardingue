import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/weather/location_service.dart';

void main() {
  group('LocationResult', () {
    test('displayName shows city and country', () {
      const result = LocationResult(
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
        country: 'France',
      );
      expect(result.displayName, 'Paris, France');
    });

    test('displayName shows city only', () {
      const result = LocationResult(
        latitude: 48.8566,
        longitude: 2.3522,
        city: 'Paris',
      );
      expect(result.displayName, 'Paris');
    });

    test('displayName shows coordinates as fallback', () {
      const result = LocationResult(
        latitude: 48.8566,
        longitude: 2.3522,
      );
      expect(result.displayName, '48.8566, 2.3522');
    });

    test('sourceLabel returns correct labels', () {
      expect(
        const LocationResult(
          latitude: 0,
          longitude: 0,
          source: LocationSource.gps,
        ).sourceLabel,
        'GPS',
      );
      expect(
        const LocationResult(
          latitude: 0,
          longitude: 0,
          source: LocationSource.ip,
        ).sourceLabel,
        'Approximatif',
      );
      expect(
        const LocationResult(
          latitude: 0,
          longitude: 0,
          source: LocationSource.search,
        ).sourceLabel,
        'Recherche',
      );
      expect(
        const LocationResult(
          latitude: 0,
          longitude: 0,
          source: LocationSource.defaultValue,
        ).sourceLabel,
        'Par d\u{00e9}faut',
      );
    });

    test('isApproximate defaults to false', () {
      const result = LocationResult(
        latitude: 0,
        longitude: 0,
      );
      expect(result.isApproximate, isFalse);
    });
  });

  group('LocationService', () {
    test('default constants are set', () {
      expect(
        LocationService.defaultLatitude,
        48.8566,
      );
      expect(
        LocationService.defaultLongitude,
        2.3522,
      );
      expect(LocationService.defaultCity, 'Paris');
    });
  });
}
