import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

class LocationState {
  final currentPosition = Rx<Position?>(null);
  final isTracking = false.obs;
  final isLoading = false.obs;
}
