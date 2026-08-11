import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A location result suitable for the existing profile/onboarding form.
class CurrentLocationResult {
  const CurrentLocationResult({
    required this.position,
    this.region,
  });

  final Position position;
  final String? region;
}

/// Uses the device's existing location services. This deliberately stops at
/// the app's existing region field because the current API has no latitude,
/// longitude, address, city, or region profile fields.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const _regions = <String>[
    'غزة',
    'شمال غزة',
    'الوسطى',
    'خانيونس',
    'رفح',
    'دير البلح',
  ];

  Future<CurrentLocationResult> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'خدمات الموقع غير مفعلة. فعّل الموقع ثم حاول مجدداً.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException('تم رفض إذن الوصول إلى موقعك.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'تم رفض إذن الموقع نهائياً. فعّله من إعدادات التطبيق.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    String? region;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        region = _matchRegion(placemarks.first);
      }
    } on Exception {
      // GPS was successful even if reverse geocoding is unavailable.
    }

    return CurrentLocationResult(position: position, region: region);
  }

  String? _matchRegion(Placemark placemark) {
    final values = <String>[
      placemark.locality ?? '',
      placemark.subLocality ?? '',
      placemark.administrativeArea ?? '',
      placemark.subAdministrativeArea ?? '',
    ].map((value) => value.toLowerCase()).toList();

    const aliases = <String, List<String>>{
      'غزة': ['غزة', 'gaza'],
      'شمال غزة': ['شمال غزة', 'north gaza'],
      'الوسطى': ['الوسطى', 'central gaza', 'deir al-balah'],
      'خانيونس': ['خانيونس', 'خان يونس', 'khan yunis', 'khan younis'],
      'رفح': ['رفح', 'rafah'],
      'دير البلح': ['دير البلح', 'deir al-balah'],
    };

    for (final region in _regions) {
      if (aliases[region]!.any(
        (alias) => values.any((value) => value.contains(alias)),
      )) {
        return region;
      }
    }
    return null;
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
