import 'package:get/get.dart';
import 'package:driver_app/features/trip/suite/trip_suite.dart';

class TripState {
  /// Driver-iin online/offline toglooch
  final isOnline = false.obs;

  /// Shineer irsen, hariu hulee bui aylal (rider request)
  final incomingTrip = Rx<Map<String, dynamic>?>(null);
  final incomingTripId = Rx<String?>(null);

  /// Driver hulee aysan idewhitei aylal
  final activeTrip = Rx<Map<String, dynamic>?>(null);
  final activeTripId = Rx<String?>(null);

  /// Trip-iin odoogiin status
  final tripStatus = Rx<TripStatus?>(null);

  /// Edniin orlogo (mock)
  final todayEarnings = 0.obs;
  final todayTrips = 0.obs;

  /// Rider-iin medeellig users/{riderId}-aas unshich avch tavina
  /// (acceptIncomingTrip uyd duudagdana).
  final riderName = ''.obs;
  final riderPhone = ''.obs;
  final riderRating = 0.0.obs;
  final riderTotalTrips = 0.obs;
  final riderPhotoUrl = ''.obs;
}
