import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/features/location/logic/location_controller.dart';
import 'package:driver_app/features/trip/suite/trip_suite.dart';


class DriverMap extends StatefulWidget {

  final bool showActiveTrip;

  const DriverMap({super.key, this.showActiveTrip = false});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  final Completer<GoogleMapController> _controllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? _mapController;

  bool _initialCameraSet = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _animateTo(double lat, double lng) async {
    final controller = await _controllerCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(lat, lng)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationController = Get.find<LocationController>();
    final tripController = Get.isRegistered<TripController>()
        ? Get.find<TripController>()
        : null;

    return Obx(() {
      final pos = locationController.state.currentPosition.value;
      final loading = locationController.state.isLoading.value;
      const fallbackUB = LatLng(47.9184, 106.9177);
      final target = pos == null ? fallbackUB : LatLng(pos.latitude, pos.longitude);

      if (pos == null) {
        debugPrint(
            '[DriverMap] no position yet (loading=$loading) — showing fallback UI');
        return ColoredBox(
          color: const Color(0xFFEEF0EC),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator(
                      color: AppTheme.primaryColor)
                else ...[
                  const Icon(Icons.location_off,
                      size: 56, color: AppTheme.textTertiary),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Could not get location.\nMake sure location services are enabled and permission granted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: locationController.getCurrentLocation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      if (_initialCameraSet) {
        _animateTo(pos.latitude, pos.longitude);
      }

      final activeTrip =
          (widget.showActiveTrip && tripController != null)
              ? tripController.state.activeTrip.value
              : null;
      final tripStatus = tripController?.state.tripStatus.value;

      final markers = _buildMarkers(
        driverLat: pos.latitude,
        driverLng: pos.longitude,
        trip: activeTrip,
      );

      final polylines = _buildPolylines(
        driverLat: pos.latitude,
        driverLng: pos.longitude,
        trip: activeTrip,
        status: tripStatus,
      );

      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(pos.latitude, pos.longitude),
          zoom: 15,
        ),
        onMapCreated: (controller) {
          if (!_controllerCompleter.isCompleted) {
            _controllerCompleter.complete(controller);
          }
          _mapController = controller;
          _initialCameraSet = true;
          debugPrint('[DriverMap] map created');
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        zoomControlsEnabled: false,
        markers: markers,
        polylines: polylines,
      );
    });
  }

  Set<Marker> _buildMarkers({
    required double driverLat,
    required double driverLng,
    Map<String, dynamic>? trip,
  }) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(driverLat, driverLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'You'),
      ),
    };

    if (trip == null) return markers;

    final pickup = trip['pickup'];
    if (pickup is GeoPoint) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickup.latitude, pickup.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: trip['pickupAddress'] as String?,
          ),
        ),
      );
    }

    final dropoff = trip['dropoff'];
    if (dropoff is GeoPoint) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(dropoff.latitude, dropoff.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Dropoff',
            snippet: trip['dropoffAddress'] as String?,
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines({
    required double driverLat,
    required double driverLng,
    Map<String, dynamic>? trip,
    TripStatus? status,
  }) {
    if (trip == null) return {};

    final pickup = trip['pickup'];
    final dropoff = trip['dropoff'];

    if (status == TripStatus.accepted && pickup is GeoPoint) {
      return {
        Polyline(
          polylineId: const PolylineId('to-pickup'),
          points: [
            LatLng(driverLat, driverLng),
            LatLng(pickup.latitude, pickup.longitude),
          ],
          color: AppTheme.primaryColor,
          width: 4,
          geodesic: true,
        ),
      };
    }

    if (status == TripStatus.inProgress && dropoff is GeoPoint) {
      return {
        Polyline(
          polylineId: const PolylineId('to-dropoff'),
          points: [
            LatLng(driverLat, driverLng),
            LatLng(dropoff.latitude, dropoff.longitude),
          ],
          color: Colors.red.shade600,
          width: 4,
          geodesic: true,
        ),
      };
    }

    return {};
  }
}
