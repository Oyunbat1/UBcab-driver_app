import 'package:flutter/material.dart';
import 'package:driver_app/core/theme/app_theme.dart';

class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isOnline ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isOnline ? AppTheme.primaryColor : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOnline ? Colors.white : const Color(0xFFBDBDBD),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? "You're Online" : "You're Offline",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOnline ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
