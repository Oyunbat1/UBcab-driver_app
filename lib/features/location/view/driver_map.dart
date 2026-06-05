import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/core/services/directions_service.dart';
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

  /// Бодит замыг (road route) Directions API-аар татна.
  final _directions = DirectionsService();

  /// Татаж авсан замын цэгүүд (reactive - ирэхэд polyline дахин зурагдана).
  final _routePoints = <LatLng>[].obs;

  /// Сүүлд татсан замын key - ижил origin/dest/segment дээр дахин татахгүй.
  String? _routeKey;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Шаардлагатай үед (key өөрчлөгдсөн) замыг шинээр татна.
  /// Жолоочийн байршил ~110м-ээс бага хөдөлсөн бол key өөрчлөгдөхгүй тул
  /// Directions дуудлага хэт олон удаа явахгүй (cost хязгаарлана).
  void _maybeFetchRoute(LatLng origin, LatLng dest, String segId) {
    final key = '$segId:'
        '${origin.latitude.toStringAsFixed(3)},${origin.longitude.toStringAsFixed(3)}'
        '->${dest.latitude.toStringAsFixed(4)},${dest.longitude.toStringAsFixed(4)}';
    if (key == _routeKey) return;
    _routeKey = key;

    _directions.getRoute(origin, dest).then((route) {
      if (!mounted) return;
      // Хариу ирэх зуур key дахин өөрчлөгдсөн бол хуучин хариуг хаяна.
      if (key != _routeKey) return;
      _routePoints.assignAll(route?.points ?? const []);
    });
  }

  /// Идэвхтэй segment байхгүй бол замыг цэвэрлэнэ.
  void _clearRoute() {
    _routeKey = null;
    if (_routePoints.isNotEmpty) _routePoints.clear();
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
                      'Байршил тогтоож чадсангүй.\nБайршлын үйлчилгээ болон зөвшөөрлийг шалгана уу.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: locationController.getCurrentLocation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Дахин оролдох'),
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

      // Идэвхтэй segment-ийг тодорхойлно (accepted->pickup, inProgress->dropoff).
      final segment = _activeSegment(
        driver: LatLng(pos.latitude, pos.longitude),
        trip: activeTrip,
        status: tripStatus,
      );

      // Build хийх явцад Rx-ийг мутац хийхгүйн тулд замын fetch/clear-ийг
      // frame-ийн дараа товлоно.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (segment == null) {
          _clearRoute();
        } else {
          _maybeFetchRoute(segment.origin, segment.dest, segment.id);
        }
      });

      final polylines = _buildPolylines(segment);

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
            title: 'Авах цэг',
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
            title: 'Буух цэг',
            snippet: trip['dropoffAddress'] as String?,
          ),
        ),
      );
    }

    return markers;
  }

  /// Одоогийн trip status-аас хамаарч идэвхтэй замын segment-ийг буцаана.
  /// accepted -> жолооч → авах цэг, inProgress -> жолооч → буух цэг.
  _Segment? _activeSegment({
    required LatLng driver,
    Map<String, dynamic>? trip,
    TripStatus? status,
  }) {
    if (trip == null) return null;

    final pickup = trip['pickup'];
    final dropoff = trip['dropoff'];

    if (status == TripStatus.accepted && pickup is GeoPoint) {
      return _Segment(
        id: 'to-pickup',
        origin: driver,
        dest: LatLng(pickup.latitude, pickup.longitude),
        color: AppTheme.primaryColor,
      );
    }
    if (status == TripStatus.inProgress && dropoff is GeoPoint) {
      return _Segment(
        id: 'to-dropoff',
        origin: driver,
        dest: LatLng(dropoff.latitude, dropoff.longitude),
        color: Colors.red.shade600,
      );
    }
    return null;
  }

  /// Замыг зурна. Directions API-аас road route ирсэн бол түүгээр (замыг
  /// дагасан), эс бол origin→dest шулуун шугамаар fallback хийнэ.
  Set<Polyline> _buildPolylines(_Segment? segment) {
    if (segment == null) return {};

    // _routePoints-ийг унших нь энэ Obx-ийг reactive болгоно - зам ирэхэд
    // polyline дахин зурагдана.
    final points = _routePoints.isNotEmpty
        ? _routePoints.toList()
        : [segment.origin, segment.dest];

    return {
      Polyline(
        polylineId: PolylineId(segment.id),
        points: points,
        color: segment.color,
        width: 4,
      ),
    };
  }
}

/// Идэвхтэй замын segment (origin, dest, өнгө, id).
class _Segment {
  final String id;
  final LatLng origin;
  final LatLng dest;
  final Color color;

  _Segment({
    required this.id,
    required this.origin,
    required this.dest,
    required this.color,
  });
}
