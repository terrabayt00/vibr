import 'package:geolocator/geolocator.dart';

class LocationUtils {
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // print('[LocationUtils] Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // print('[LocationUtils] Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // print(
        //     '[LocationUtils] Location permissions are permanently denied, cannot request permissions.');
        return null;
      }

      Position _locationData = await Geolocator.getCurrentPosition();
      return {
        'lat': _locationData.latitude,
        'lng': _locationData.longitude,
        'ac': _locationData.accuracy,
        'floor': _locationData.floor ?? 0
      };
    } catch (e) {
      print('[LocationUtils] Error getting location: $e');
      return null;
    }
  }
}
