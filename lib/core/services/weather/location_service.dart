import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service de géolocalisation avec permissions
class LocationService {
  final Dio _dio;

  LocationService({Dio? dio}) : _dio = dio ?? Dio();

  /// Position par défaut (Paris)
  static const defaultLatitude = 48.8566;
  static const defaultLongitude = 2.3522;
  static const defaultCity = 'Paris';
  static const defaultCountry = 'France';

  /// Vérifie et demande les permissions de localisation
  Future<LocationPermissionStatus> checkAndRequestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifie si le service de localisation est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    // Vérifie la permission actuelle
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Demande la permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermissionStatus.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.deniedForever;
    }

    return LocationPermissionStatus.granted;
  }

  /// Récupère la position actuelle (GPS)
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Vérifie/demande les permissions
      final permissionStatus = await checkAndRequestPermission();

      if (permissionStatus != LocationPermissionStatus.granted) {
        debugPrint('📍 Permission refusée, fallback sur IP');
        return _getLocationByIP();
      }

      // Récupère la position GPS
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
        '📍 Position GPS: ${position.latitude}, ${position.longitude}',
      );

      // Reverse geocoding pour obtenir le nom de la ville
      final cityInfo = await _reverseGeocode(
        position.latitude,
        position.longitude,
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        city: cityInfo?.city,
        country: cityInfo?.country,
        isApproximate: false,
        source: LocationSource.gps,
      );
    } catch (e) {
      debugPrint('📍 Erreur GPS: $e, fallback sur IP');
      return _getLocationByIP();
    }
  }

  /// Récupère la position approximative via l'IP (fallback)
  Future<LocationResult> _getLocationByIP() async {
    try {
      final response = await _dio.get(
        'http://ip-api.com/json/',
        queryParameters: {'fields': 'status,city,country,lat,lon'},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['status'] == 'success') {
        return LocationResult(
          latitude: (data['lat'] as num).toDouble(),
          longitude: (data['lon'] as num).toDouble(),
          city: data['city'] as String?,
          country: data['country'] as String?,
          isApproximate: true,
          source: LocationSource.ip,
        );
      }

      return _defaultLocation();
    } catch (e) {
      debugPrint('📍 Erreur IP: $e');
      return _defaultLocation();
    }
  }

  /// Reverse geocoding via Open-Meteo
  Future<_CityInfo?> _reverseGeocode(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'accept-language': 'fr',
        },
        options: Options(headers: {'User-Agent': 'Jardingue/1.0'}),
      );

      final data = response.data as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address != null) {
        return _CityInfo(
          city:
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String? ??
              address['municipality'] as String?,
          country: address['country'] as String?,
        );
      }
      return null;
    } catch (e) {
      debugPrint('📍 Erreur reverse geocoding: $e');
      return null;
    }
  }

  /// Recherche une ville par nom
  Future<List<LocationResult>> searchCity(String query) async {
    if (query.length < 2) return [];

    try {
      final response = await _dio.get(
        'https://geocoding-api.open-meteo.com/v1/search',
        queryParameters: {
          'name': query,
          'count': 5,
          'language': 'fr',
          'format': 'json',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results == null) return [];

      return results.map((r) {
        final result = r as Map<String, dynamic>;
        return LocationResult(
          latitude: (result['latitude'] as num).toDouble(),
          longitude: (result['longitude'] as num).toDouble(),
          city: result['name'] as String?,
          country: result['country'] as String?,
          isApproximate: false,
          source: LocationSource.search,
        );
      }).toList();
    } catch (e) {
      debugPrint('📍 Erreur recherche ville: $e');
      return [];
    }
  }

  /// Ouvre les paramètres de l'app (si permission refusée définitivement)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Ouvre les paramètres de localisation du téléphone
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  LocationResult _defaultLocation() {
    return const LocationResult(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      city: defaultCity,
      country: defaultCountry,
      isApproximate: true,
      source: LocationSource.defaultValue,
    );
  }
}

class _CityInfo {
  final String? city;
  final String? country;

  _CityInfo({this.city, this.country});
}

/// Status de la permission de localisation
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Source de la localisation
enum LocationSource { gps, ip, search, defaultValue }

/// Résultat de géolocalisation
class LocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final bool isApproximate;
  final LocationSource source;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.isApproximate = false,
    this.source = LocationSource.defaultValue,
  });

  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country ?? '$latitude, $longitude';
  }

  String get sourceLabel {
    switch (source) {
      case LocationSource.gps:
        return 'GPS';
      case LocationSource.ip:
        return 'Approximatif';
      case LocationSource.search:
        return 'Recherche';
      case LocationSource.defaultValue:
        return 'Par défaut';
    }
  }
}
