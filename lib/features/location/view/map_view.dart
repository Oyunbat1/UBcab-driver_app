import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/features/location/logic/location_controller.dart';
import 'package:driver_app/features/location/view/driver_map.dart';

/// Standalone map view (debug / fallback). Used outside the trip stack.
class MapView extends StatelessWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocationController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Map',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DriverMap()),

          // Coordinate readout
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Obx(() {
              final pos = controller.state.currentPosition.value;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  pos == null
                      ? 'Locating...'
                      : 'Lat: ${pos.latitude.toStringAsFixed(4)}  ·  Lon: ${pos.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }),
          ),

          // Refresh location button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: AppTheme.primaryColor,
              onPressed: () => controller.getCurrentLocation(),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
