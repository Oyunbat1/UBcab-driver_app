import 'package:get/get.dart';
import 'package:driver_app/features/trip/logic/trip_api.dart';
import 'package:driver_app/features/trip/logic/trip_controller.dart';
import 'package:driver_app/features/location/logic/location_api.dart';
import 'package:driver_app/features/location/logic/location_controller.dart';

class TripBinding extends Bindings {
  @override
  void dependencies() {
    // Trip-g permanent bolgoj home <-> navigation hoorondoo state-g hadgalna
    Get.put(TripApi(), permanent: true);
    Get.put(TripController(tripApi: Get.find<TripApi>()), permanent: true);
    Get.lazyPut(() => LocationApi());
    Get.lazyPut(() => LocationController(locationApi: Get.find<LocationApi>()));
  }
}
