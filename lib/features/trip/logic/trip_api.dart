import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/core/constants/firebase_constants.dart';

class TripApi {
  final _firestore = FirebaseFirestore.instance;


  Stream<QuerySnapshot> watchRequestedTrips() {
    return _firestore
        .collection(FirebaseConstants.tripsCollection)
        .where('status', isEqualTo: 'requested')
        .where('driverId', isEqualTo: null)
        .snapshots();
  }


  Stream<DocumentSnapshot> watchTrip(String tripId) {
    return _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .snapshots();
  }


  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(uid)
        .get();
    return doc.data();
  }

  /// Driver duudlaga hulee awah heseg.
  /// Trip doc deer driverId-g bichij, status-g 'accepted' bolgono.
  /// Rider talaas herwee driver huselt awbal  "Driver found" gej haruulah heseg.
  Future<void> acceptTrip({
    required String tripId,
    required String driverId,
  }) async {
    await _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .update({
      'driverId': driverId,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTripStatus({
    required String tripId,
    required String status,
  }) async {
    await _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId)
        .update({'status': status});
  }

  /// Aylal duusgah uyed:
  /// - trip doc-iig 'completed' bolgono
  /// - driver-iin totalEarnings + totalTrips-iig nemne
  /// - rider-iin totalSpent + totalTrips-iig nemne
  ///
  Future<void> completeTripAndSettleTotals({
    required String tripId,
    required String riderId,
    required String driverId,
    required int fare,
  }) async {
    final batch = _firestore.batch();
    final tripRef = _firestore
        .collection(FirebaseConstants.tripsCollection)
        .doc(tripId);
    final driverRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(driverId);
    final riderRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(riderId);

    batch.update(tripRef, {
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      driverRef,
      {
        'totalEarnings': FieldValue.increment(fare),
        'totalTrips': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
    batch.set(
      riderRef,
      {
        'totalSpent': FieldValue.increment(fare),
        'totalTrips': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
