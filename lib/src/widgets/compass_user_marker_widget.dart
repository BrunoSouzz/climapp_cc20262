import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Marcador de posição do usuário estilo Google Maps com seta direcional da bússola.
class CompassUserMarkerWidget extends StatelessWidget {
  const CompassUserMarkerWidget({
    required this.heading,
    super.key,
  });

  final double heading;

  @override
  Widget build(BuildContext context) {
    final double headingRadians = heading * (math.pi / 180);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4463D5).withValues(alpha: 0.22),
        border: Border.all(
          color: const Color(0xFF7693FF).withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF05051F),
            border: Border.all(
              color: Colors.white,
              width: 2.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: headingRadians,
            child: const Icon(
              Icons.navigation,
              color: Color(0xFF7693FF),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
