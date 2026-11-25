import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bússola flutuante estilo Google Maps; ao tocar, alinha o mapa ao Norte.
class FloatingCompassWidget extends StatelessWidget {
  const FloatingCompassWidget({
    required this.heading,
    this.onTap,
    super.key,
  });

  final double heading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double normalizedHeading = (heading % 360 + 360) % 360;
    final double headingRadians = normalizedHeading * (math.pi / 180);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: 'Alinhar mapa ao Norte',
          child: Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFF7693FF).withValues(alpha: 0.75),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'N',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Transform.rotate(
                  angle: -headingRadians,
                  child: const Icon(
                    Icons.explore,
                    size: 32,
                    color: Color(0xFF7693FF),
                  ),
                ),
                Text(
                  '${normalizedHeading.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
