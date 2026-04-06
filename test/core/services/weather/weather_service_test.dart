import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/services/weather/weather_service.dart';

void main() {
  group('WeatherException', () {
    test('toString returns message', () {
      const msg = 'Erreur reseau';
      final exception = WeatherException(msg);
      expect(exception.toString(), msg);
      expect(exception.message, msg);
    });
  });

  group('WeatherService', () {
    test('can be created with default Dio', () {
      final service = WeatherService();
      expect(service, isNotNull);
    });

    test('throws WeatherException on invalid coords', () {
      final service = WeatherService();
      // Open-Meteo rejects clearly invalid coords
      expect(
        () => service.getWeather(
          latitude: 999,
          longitude: 999,
        ),
        throwsA(isA<WeatherException>()),
      );
    });
  });
}
