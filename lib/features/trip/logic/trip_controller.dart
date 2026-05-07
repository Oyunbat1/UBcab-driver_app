import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:driver_app/app/routes/app_routes.dart';
import 'package:driver_app/core/services/audio_service.dart';
import 'package:driver_app/features/location/logic/location_controller.dart';
import 'package:driver_app/features/trip/suite/trip_suite.dart';

class TripController extends GetxController {
  final TripApi tripApi;
  final state = TripState();

  StreamSubscription? _requestsSubscription;
  StreamSubscription? _activeTripSubscription;

  TripController({required this.tripApi});


  AudioService get _audio => Get.isRegistered<AudioService>()
      ? Get.find<AudioService>()
      : Get.put(AudioService(), permanent: true);
  LocationController get _location => Get.find<LocationController>();


  void toggleOnline() {
    state.isOnline.value = !state.isOnline.value;

    if (state.isOnline.value) {
      _location.startTracking();
      _startListeningForTrips();
    } else {
      _location.stopTracking();
      _stopListeningForTrips();
    }
  }

  void _startListeningForTrips() {
    _requestsSubscription?.cancel();
    _requestsSubscription =
        tripApi.watchRequestedTrips().listen((snapshot) {
      // Idewhitei aylaltai bol shine duudlaga awahgu
      if (state.activeTripId.value != null) return;

      // Shineer irsen aylaliin ehniig avch dialog haruulna
      if (snapshot.docs.isEmpty) {
        _audio.stopIncomingLoop();
        state.incomingTrip.value = null;
        state.incomingTripId.value = null;
        return;
      }

      final doc = snapshot.docs.first;

      if (state.incomingTripId.value == doc.id) return;

      state.incomingTripId.value = doc.id;
      state.incomingTrip.value = doc.data() as Map<String, dynamic>;

      // Looping ringtone + chichireh.
      _audio.startIncomingLoop();
    });
  }

  void _stopListeningForTrips() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
    _audio.stopIncomingLoop();
    state.incomingTrip.value = null;
    state.incomingTripId.value = null;
  }

  /// Duudlaga hulee awah:
  /// 1. Incoming sound aa zogsoono
  /// 2. Firestore deer driverId, status: 'accepted' bichne
  /// 3. Trip doc-g real time-aar sonsono
  /// 4. Location push-iig idewhjuulne
  /// 5. NavigationView ruu shiljine
  Future<void> acceptIncomingTrip() async {
    final tripId = state.incomingTripId.value;
    final tripData = state.incomingTrip.value;
    if (tripId == null || tripData == null) return;

    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) return;

    await _audio.stopIncomingLoop();

    await tripApi.acceptTrip(tripId: tripId, driverId: driverId);

    state.activeTripId.value = tripId;
    state.activeTrip.value = {
      ...tripData,
      'driverId': driverId,
      'status': 'accepted',
    };
    state.tripStatus.value = TripStatus.accepted;

    // Incoming-g tseverlene
    state.incomingTrip.value = null;
    state.incomingTripId.value = null;


    final riderId = tripData['riderId'] as String?;
    if (riderId != null && riderId.isNotEmpty) {
      _fetchRiderInfo(riderId);
    }

    // Location push-iig idewhjuulne (5 sek tutamd push hiine).
    _location.bindActiveTrip(tripId);

    // Idewhitei aylaliig real-time-aar sonsono (rider talaas tsutslah magadlaltai)
    _activeTripSubscription =
        tripApi.watchTrip(tripId).listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      state.activeTrip.value = data;

      final status = data['status'] as String?;
      if (status == 'cancelled') {
        Get.snackbar('Trip', 'Trip cancelled by rider');
        _resetActiveTrip();
        Get.offAllNamed(AppRoutes.home);
      }
    });

    Get.toNamed(AppRoutes.navigation);
  }

  /// Rider-iin user doc-iig avch state-d tavina
  Future<void> _fetchRiderInfo(String riderId) async {
    try {
      final data = await tripApi.getUserDoc(riderId);
      if (data == null) return;
      state.riderName.value = (data['name'] as String?)?.trim().isNotEmpty ==
              true
          ? data['name']
          : 'Rider';
      state.riderPhone.value = data['phone'] ?? '';
      state.riderRating.value = (data['rating'] ?? 4.8).toDouble();
      state.riderTotalTrips.value = data['totalTrips'] ?? 0;
      state.riderPhotoUrl.value = data['photoUrl'] ?? '';
    } catch (_) {

    }
  }


  /// Trip Firestore deer huleegdsen heveeree uldeh tul oor driver awah bolomjtoi.
  void declineIncomingTrip() {
    _audio.stopIncomingLoop();
    state.incomingTrip.value = null;
    state.incomingTripId.value = null;
  }

  /// Driver pickup deer hurelee gej zarlah
  Future<void> markArrived() async {
    final tripId = state.activeTripId.value;
    if (tripId == null) return;
    _audio.playArrived();
    await tripApi.updateTripStatus(tripId: tripId, status: 'arriving');
    state.tripStatus.value = TripStatus.arriving;
  }

  /// Aylal ehluulj baigaag zarlah
  Future<void> startTrip() async {
    final tripId = state.activeTripId.value;
    if (tripId == null) return;
    _audio.playStart();
    await tripApi.updateTripStatus(tripId: tripId, status: 'inProgress');
    state.tripStatus.value = TripStatus.inProgress;
  }

  /// Aylal duusgeh + orlogo nemne (atomic batch).
  /// trips/{tripId}.status -> 'completed', completedAt
  /// users/{driverId}.totalEarnings + 1 trip
  /// users/{riderId}.totalSpent + 1 trip
  Future<void> completeTrip() async {
    final tripId = state.activeTripId.value;
    final trip = state.activeTrip.value;
    if (tripId == null || trip == null) return;

    final fare = (trip['fare'] as num?)?.toInt() ?? 0;
    final riderId = trip['riderId'] as String? ?? '';
    final driverId = trip['driverId'] as String? ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';

    _audio.playComplete();

    if (riderId.isEmpty || driverId.isEmpty) {
      await tripApi.updateTripStatus(tripId: tripId, status: 'completed');
    } else {
      await tripApi.completeTripAndSettleTotals(
        tripId: tripId,
        riderId: riderId,
        driverId: driverId,
        fare: fare,
      );
    }
    state.tripStatus.value = TripStatus.completed;


    state.todayEarnings.value += fare;
    state.todayTrips.value += 1;

    _resetActiveTrip();
    Get.offAllNamed(AppRoutes.home);
  }

  void _resetActiveTrip() {
    _activeTripSubscription?.cancel();
    _activeTripSubscription = null;
    state.activeTrip.value = null;
    state.activeTripId.value = null;
    state.tripStatus.value = null;
    state.riderName.value = '';
    state.riderPhone.value = '';
    state.riderRating.value = 0.0;
    state.riderTotalTrips.value = 0;
    state.riderPhotoUrl.value = '';
    _location.bindActiveTrip(null);
  }

  @override
  void onClose() {
    _requestsSubscription?.cancel();
    _activeTripSubscription?.cancel();
    _audio.stopIncomingLoop();
    super.onClose();
  }
}
