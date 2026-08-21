import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

/// City + country pair derived from reverse geocoding the device's GPS fix.
class CurrentLocation {
  const CurrentLocation({required this.city, required this.country});

  final String city;
  final String country;

  String get label => country.isNotEmpty ? '$city, $country' : city;
}

enum LocationErrorReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  geocodeFailed,
}

class LocationException implements Exception {
  const LocationException(this.reason, this.message);

  final LocationErrorReason reason;
  final String message;

  @override
  String toString() => message;
}

/// Resolves the device's current GPS position into a human-readable
/// city/country label for the Home greeting header.
class CurrentLocationController extends AsyncNotifier<CurrentLocation> {
  @override
  Future<CurrentLocation> build() => _resolve();

  /// Re-runs permission checks and re-fetches — call this from a retry tap.
  Future<void> refresh() async {
    state = const AsyncValue<CurrentLocation>.loading();
    state = await AsyncValue.guard(_resolve);
  }

  /// Opens the app's OS settings page — the only way out once permission
  /// has been permanently denied, since requestPermission() won't
  /// re-prompt at that point.
  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<CurrentLocation> _resolve() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(LocationErrorReason.serviceDisabled,
          'Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
            LocationErrorReason.permissionDenied, 'Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationErrorReason.permissionDeniedForever,
          'Location permission permanently denied');
    }

    final Position position = await Geolocator.getCurrentPosition(

        // locationSettings:
        //     const LocationSettings(accuracy: LocationAccuracy.medium),
        );

    final List<geocoding.Placemark> placemarks = await geocoding
        .placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isEmpty) {
      throw const LocationException(
          LocationErrorReason.geocodeFailed, 'Could not resolve address');
    }

    final geocoding.Placemark place = placemarks.first;
    final String city = place.locality?.isNotEmpty == true
        ? place.locality!
        : (place.subAdministrativeArea ??
            place.administrativeArea ??
            'Unknown');
    final String country = place.country ?? '';

    return CurrentLocation(city: city, country: country);
  }
}

final AsyncNotifierProvider<CurrentLocationController, CurrentLocation>
    currentLocationProvider =
    AsyncNotifierProvider<CurrentLocationController, CurrentLocation>(
        CurrentLocationController.new);
