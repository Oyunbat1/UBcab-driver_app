import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:driver_app/features/location/state/location_state.dart';
import 'package:driver_app/features/location/logic/location_api.dart';

class LocationController extends GetxController {
  final LocationApi locationApi;
  final state = LocationState();

  StreamSubscription<Position>? _trackingSubscription;


  String? _activeTripId;
  DateTime? _lastPushAt;
  static const Duration _pushInterval = Duration(seconds: 5);

  LocationController({required this.locationApi});

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    state.isLoading.value = true;
    try {
      final hasPermission = await locationApi.checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('[LocationController] permission denied');
        Get.snackbar(
          'Permission',
          'Location permission is required to show the map',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      final position = await locationApi.getCurrentPosition();
      debugPrint(
          '[LocationController] got position: ${position.latitude}, ${position.longitude}');
      state.currentPosition.value = position;
    } catch (e) {
      debugPrint('[LocationController] getCurrentLocation FAILED: $e');
      Get.snackbar(
        'Location Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  /// Driver online bolson uyed location track hiih heseg maani
  void startTracking() {
    if (state.isTracking.value) return;

    _trackingSubscription?.cancel();
    _trackingSubscription = locationApi.trackPosition().listen((position) {
      state.currentPosition.value = position;
      _maybePushToActiveTrip(position);
    });
    state.isTracking.value = true;
  }

  void stopTracking() {
    _trackingSubscription?.cancel();
    _trackingSubscription = null;
    state.isTracking.value = false;
    _activeTripId = null;
    _lastPushAt = null;
  }


  void bindActiveTrip(String? tripId) {
    _activeTripId = tripId;
    _lastPushAt = null;
    final pos = state.currentPosition.value;
    if (pos != null && tripId != null) {
      _maybePushToActiveTrip(pos);
    }
  } /// ????

  Future<void> _maybePushToActiveTrip(Position pos) async {
    final tripId = _activeTripId;
    if (tripId == null) return;
    final now = DateTime.now();
    if (_lastPushAt != null &&
        now.difference(_lastPushAt!) < _pushInterval) {
      return;
    }
    _lastPushAt = now;
    try {
      await locationApi.pushDriverLocation(tripId, pos.latitude, pos.longitude);
    } catch (_) {
    }
  }

  @override
  void onClose() {
    _trackingSubscription?.cancel();
    super.onClose();
  }
}
