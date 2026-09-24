import 'package:flutter/material.dart';

/// A modern, beautiful logo icon for Qadaa App, combining:
/// 1. Crescent Moon (🌙) for Fasting (الصيام)
/// 2. Spiritual Star/Light (✨) for Prayer & Worship (الصلاة والعبادات)
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
    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.nightlight_round,
              size: size * 0.85,
              color: const Color(0xFFF59E0B),
            ),
            Positioned(
              top: size * 0.05,
              right: size * 0.05,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.42,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Crescent Moon for Fasting
            Icon(
              Icons.nightlight_round,
              size: size * 0.58,
              color: const Color(0xFFFBBF24),
            ),
            // Star/Spiritual Spark for Prayer & Devotion
            Positioned(
              top: size * 0.12,
              right: size * 0.14,
              child: Icon(
                Icons.auto_awesome,
                size: size * 0.32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
