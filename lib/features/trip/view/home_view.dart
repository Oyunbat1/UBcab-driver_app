import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_app/app/routes/app_routes.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/features/location/logic/location_controller.dart';
import 'package:driver_app/features/location/components/route_polyline.dart';
import 'package:driver_app/features/location/view/driver_map.dart';
import 'package:driver_app/features/trip/logic/trip_controller.dart';
import 'package:driver_app/features/trip/components/online_toggle.dart';
import 'package:driver_app/features/trip/components/earnings_card.dart';
import 'package:driver_app/features/trip/components/trip_request_dialog.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final tripController = Get.find<TripController>();
    final locationController = Get.find<LocationController>();

    return Scaffold(
      body: Stack(
        children: [
          // Real Google Map suuriig — driver-iin sjoo bairshil center deer baina.
          const Positioned.fill(child: DriverMap()),

          // Top bar: greeting + profile
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Сайн уу, Жолооч 👋',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.profile),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(Icons.person,
                              size: 18, color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Online toggle (floating, top center under header)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => OnlineToggle(
                    isOnline: tripController.state.isOnline.value,
                    onToggle: tripController.toggleOnline,
                  )),
            ),
          ),

          // Current location button
          Positioned(
            bottom: 220,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.my_location,
                    color: AppTheme.primaryColor, size: 18),
                onPressed: () => locationController.getCurrentLocation(),
              ),
            ),
          ),

          // Bottom: either trip request, or earnings card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              final incoming = tripController.state.incomingTrip.value;

              if (incoming != null) {
                return TripRequestDialog(
                  trip: incoming,
                  onAccept: tripController.acceptIncomingTrip,
                  onDecline: tripController.declineIncomingTrip,
                );
              }

              return _buildBottomSheet(tripController);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(TripController tripController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => EarningsCard(
                todayEarnings: tripController.state.todayEarnings.value,
                todayTrips: tripController.state.todayTrips.value,
              )),
          const SizedBox(height: 14),
          Obx(() {
            if (!tripController.state.isOnline.value) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFB28704)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Та offline байна. Аялал авахын тулд online болоорой.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8B6500)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  RoutePolyline(),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Online байна. Аялал хүлээж байна...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
