import 'package:flutter/material.dart';

/// A modern, ultra-premium logo icon for Qadaa App, representing:
/// 1. Mosque Arch & Spiritual Mihrab (الصلاة والعبادات)
/// 2. Crescent Moon & Star for Fasting (الصيام)
/// 3. Prayer Beads / Tasbeeh (المسبحة)
class AppLogoIcon extends StatelessWidget {
  final double size;
  final bool showBackground;

  const AppLogoIcon({
    super.key,
    this.size = 28,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: showBackground
            ? [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF0F766E),
              child: Icon(
                Icons.mosque_rounded,
                size: size * 0.6,
                color: const Color(0xFFFBBF24),
              ),
            );
          },
        ),
      ),
    );
  }
}
