import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service de géolocalisation avec permissions
class LocationService {
  final Dio _dio;

  LocationService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ));

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
        final issue = switch (permissionStatus) {
          LocationPermissionStatus.serviceDisabled =>
            LocationIssue.serviceDisabled,
          LocationPermissionStatus.deniedForever =>
            LocationIssue.permissionDeniedForever,
          _ => LocationIssue.permissionDenied,
        };
        debugPrint('📍 Permission refusée ($permissionStatus), fallback sur IP');
        return _getLocationByIP(issue);
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
      return _getLocationByIP(LocationIssue.gpsError);
    }
  }

  /// Récupère la position approximative via l'IP (fallback).
  /// [originalIssue] est le problème initial (permission, GPS...).
  Future<LocationResult> _getLocationByIP([LocationIssue? originalIssue]) async {
    // Essaie ipapi.co puis ip-api.com en fallback
    for (final endpoint in _ipGeoEndpoints) {
      try {
        final response = await _dio.get(endpoint.url);
        final data = response.data as Map<String, dynamic>;

        final lat = data[endpoint.latKey] as num?;
        final lon = data[endpoint.lonKey] as num?;

        if (lat != null && lon != null) {
          return LocationResult(
            latitude: lat.toDouble(),
            longitude: lon.toDouble(),
            city: data[endpoint.cityKey] as String?,
            country: data[endpoint.countryKey] as String?,
            isApproximate: true,
            source: LocationSource.ip,
            issue: originalIssue,
          );
        }
      } catch (e) {
        debugPrint('📍 Erreur ${endpoint.url}: $e');
      }
    }
    return _defaultLocation(originalIssue ?? LocationIssue.networkError);
  }

  static const _ipGeoEndpoints = [
    _IpGeoEndpoint(
      url: 'https://ipapi.co/json/',
      latKey: 'latitude', lonKey: 'longitude',
      cityKey: 'city', countryKey: 'country_name',
    ),
    _IpGeoEndpoint(
      url: 'http://ip-api.com/json/?fields=lat,lon,city,country',
      latKey: 'lat', lonKey: 'lon',
      cityKey: 'city', countryKey: 'country',
    ),
  ];

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

  LocationResult _defaultLocation(LocationIssue issue) {
    return LocationResult(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      city: defaultCity,
      country: defaultCountry,
      isApproximate: true,
      source: LocationSource.defaultValue,
      issue: issue,
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

/// Problème rencontré lors de la géolocalisation
enum LocationIssue {
  /// Le service de localisation est désactivé sur le téléphone
  serviceDisabled,

  /// L'utilisateur a refusé la permission
  permissionDenied,

  /// L'utilisateur a refusé la permission définitivement
  permissionDeniedForever,

  /// Erreur GPS (timeout, position indisponible...)
  gpsError,

  /// Erreur réseau lors du fallback IP
  networkError,
}

/// Résultat de géolocalisation
class LocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final bool isApproximate;
  final LocationSource source;

  /// Décrit le problème de localisation rencontré (null si tout va bien).
  final LocationIssue? issue;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.isApproximate = false,
    this.source = LocationSource.defaultValue,
    this.issue,
  });

  String get displayName {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country ?? '$latitude, $longitude';
  }

  String get sourceLabel => switch (source) {
    LocationSource.gps => 'GPS',
    LocationSource.ip => 'Approximatif',
    LocationSource.search => 'Recherche',
    LocationSource.defaultValue => 'Par défaut',
  };

  /// Message explicatif du problème de localisation.
  String? get issueMessage => switch (issue) {
    LocationIssue.serviceDisabled =>
      'Le service de localisation est désactivé.'
      'Activez-le dans les paramètres de votre téléphone.',
    LocationIssue.permissionDenied =>
      'L\'accès à la localisation a été refusé.'
      'Autorisez Jardingue dans les paramètres.',
    LocationIssue.permissionDeniedForever =>
      'L\'accès à la localisation est bloqué.'
      'Modifiez les permissions dans les paramètres de l\'application.',
    LocationIssue.gpsError =>
      'Impossible d\'obtenir votre position GPS. '
      'Vérifiez que la localisation est activée.',
    LocationIssue.networkError =>
      'Impossible de déterminer votre position.'
      'Vérifiez votre connexion internet.',
    null => null,
  };

  /// true si la localisation a rencontré un problème et utilise un fallback.
  bool get hasFallback => issue != null;

  /// true si l'utilisateur peut résoudre le problème via les réglages de l'app.
  bool get canOpenAppSettings =>
      issue == LocationIssue.permissionDenied ||
      issue == LocationIssue.permissionDeniedForever;

  /// true si l'utilisateur peut résoudre le problème via les réglages du téléphone.
  bool get canOpenLocationSettings =>
      issue == LocationIssue.serviceDisabled;
}

class _IpGeoEndpoint {
  final String url;
  final String latKey;
  final String lonKey;
  final String cityKey;
  final String countryKey;

  const _IpGeoEndpoint({
    required this.url,
    required this.latKey,
    required this.lonKey,
    required this.cityKey,
    required this.countryKey,
  });
}
