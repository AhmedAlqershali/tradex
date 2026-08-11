import 'dart:async';

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

  static const supportedRegions = <String>[
    'غزة',
    'شمال غزة',
    'الوسطى',
    'خانيونس',
    'رفح',
    'دير البلح',
  ];

  Future<CurrentLocationResult> getCurrentLocation() async {
    try {
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
          timeLimit: Duration(seconds: 15),
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
    } on LocationException {
      rethrow;
    } on LocationServiceDisabledException {
      throw const LocationException(
        'خدمات الموقع غير مفعلة. فعّل الموقع ثم حاول مجدداً.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        'تم رفض إذن الوصول إلى موقعك. اسمح للتطبيق باستخدام الموقع ثم حاول مجدداً.',
      );
    } on TimeoutException {
      throw const LocationException(
        'استغرق تحديد موقعك وقتاً طويلاً. تأكد من تفعيل GPS ثم حاول مجدداً.',
      );
    }
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
      'الوسطى': ['الوسطى', 'central gaza'],
      'خانيونس': ['خانيونس', 'خان يونس', 'khan yunis', 'khan younis'],
      'رفح': ['رفح', 'rafah'],
      'دير البلح': ['دير البلح', 'deir al-balah'],
    };

    final orderedAliases = aliases.entries
        .expand(
          (entry) => entry.value.map(
            (alias) => (region: entry.key, alias: alias.toLowerCase()),
          ),
        )
        .toList()
      ..sort((a, b) => b.alias.length.compareTo(a.alias.length));

    for (final entry in orderedAliases) {
      if (values.any((value) => value == entry.alias)) {
        return entry.region;
      }
    }
    for (final entry in orderedAliases) {
      if (values.any((value) => value.contains(entry.alias))) {
        return entry.region;
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
