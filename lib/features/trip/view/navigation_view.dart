import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/features/location/view/driver_map.dart';
import 'package:driver_app/features/trip/components/rider_profile_sheet.dart';
import 'package:driver_app/features/trip/suite/trip_suite.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

  String _statusTitle(TripStatus? status) {
    switch (status) {
      case TripStatus.accepted:
        return 'Авах цэг рүү явж байна';
      case TripStatus.arriving:
        return 'Авах цэгт ирлээ';
      case TripStatus.inProgress:
        return 'Аялал үргэлжилж байна';
      case TripStatus.completed:
        return 'Аялал дууслаа';
      default:
        return 'Аялал';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TripController>();

    return Scaffold(
      body: Stack(
        children: [
          // Real map: driver -> pickup polyline (status accepted),
          // driver -> dropoff polyline (status inProgress).
          const Positioned.fill(child: DriverMap(showActiveTrip: true)),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              final status = controller.state.tripStatus.value;
              return Container(
                width: double.infinity,
                color: AppTheme.primaryColor,
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusTitle(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Болгоомжтой жолоодоорой',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Bottom card: rider info + status action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              final trip = controller.state.activeTrip.value;
              if (trip == null) return const SizedBox();
              final status = controller.state.tripStatus.value;

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Rider info — tap to open profile
                    InkWell(
                      onTap: RiderProfileSheet.show,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: AppTheme.primaryLight,
                              child: Icon(Icons.person,
                                  color: AppTheme.primaryColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.state.riderName.value.isEmpty
                                        ? 'Зорчигч'
                                        : controller.state.riderName.value,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '⭐ ${controller.state.riderRating.value.toStringAsFixed(1)} · Tap to view',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppTheme.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 24),

                    // Pickup/dropoff (real address from trip doc)
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 8, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (trip['pickupAddress'] as String?)?.isNotEmpty ==
                                    true
                                ? trip['pickupAddress']
                                : 'Авах цэг',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: Colors.red.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (trip['dropoffAddress'] as String?)?.isNotEmpty ==
                                    true
                                ? trip['dropoffAddress']
                                : 'Буух цэг',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Status action button — flow: accepted → arrived → inProgress → completed
                    _buildActionButton(controller, status),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(TripController controller, TripStatus? status) {
    if (status == TripStatus.accepted) {
      return ElevatedButton(
        onPressed: controller.markArrived,
        child: const Text("Би ирлээ"),
      );
    }
    if (status == TripStatus.arriving) {
      return ElevatedButton(
        onPressed: controller.startTrip,
        child: const Text('Аялал эхлүүлэх'),
      );
    }
    if (status == TripStatus.inProgress) {
      return ElevatedButton(
        onPressed: controller.completeTrip,
        child: const Text('Аялал дуусгах'),
      );
    }
    return const SizedBox(height: 52);
  }
}
