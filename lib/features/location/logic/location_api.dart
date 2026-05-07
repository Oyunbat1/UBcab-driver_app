import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/core/constants/firebase_constants.dart';
import 'package:geolocator/geolocator.dart';

class LocationApi {
  final _firestore = FirebaseFirestore.instance;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Driver-iin bairshlig tasraltgui hynah  zoriulsan stream
  Stream<Position> trackPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }


  Future<void> pushDriverLocation(
      String tripId, double lat, double lng) async {
    await _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .update({
      'driverLocation': GeoPoint(lat, lng),
      'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
