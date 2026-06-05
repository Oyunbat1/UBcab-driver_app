import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:driver_app/core/theme/app_theme.dart';
import 'package:driver_app/features/auth/logic/auth_controller.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.checkSession();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Drive now',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Жолооч түнш',
              style: TextStyle(fontSize: 14, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
