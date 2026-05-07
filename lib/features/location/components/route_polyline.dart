import 'package:flutter/material.dart';
import 'package:driver_app/core/theme/app_theme.dart';



class RoutePolyline extends StatefulWidget {
  const RoutePolyline({super.key});

  @override
  State<RoutePolyline> createState() => _RoutePolylineState();
}

class _RoutePolylineState extends State<RoutePolyline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(
              alpha: 0.4 + (_controller.value * 0.6),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
