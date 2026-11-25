import 'package:climapp_cc20262/src/models/region_weather_model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CompassInfoPanelWidget extends StatelessWidget {
  const CompassInfoPanelWidget({
    required this.position,
    required this.heading,
    required this.selectedRegion,
    this.isFetchingRegionWeather = false,
    super.key,
  });

  final LatLng position;
  final double heading;
  final RegionWeatherModel? selectedRegion;
  final bool isFetchingRegionWeather;

  @override
  Widget build(BuildContext context) {
    final LatLng displayedCoords = selectedRegion?.position ?? position;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF00457D).withValues(alpha: 0.96),
            const Color(0xFF05051F).withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          color: const Color(0xFF4463D5).withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _HeadingBadge(heading: heading),
              const SizedBox(width: 10),
              Expanded(child: _CoordinatesCard(position: displayedCoords)),
            ],
          ),
          const SizedBox(height: 10),
          if (isFetchingRegionWeather)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7693FF),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Consultando clima da região...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          else if (selectedRegion != null)
            _WeatherSummaryCard(region: selectedRegion!)
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Toque em um marcador ou em qualquer ponto do mapa para ver o clima.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeadingBadge extends StatelessWidget {
  const _HeadingBadge({required this.heading});

  final double heading;

  static const List<String> _directions = [
    'N',
    'NE',
    'L',
    'SE',
    'S',
    'SO',
    'O',
    'NO',
  ];

  @override
  Widget build(BuildContext context) {
    final double normalizedHeading = (heading % 360 + 360) % 360;
    final int directionIndex = ((normalizedHeading + 22.5) ~/ 45) % 8;
    final String cardinal = _directions[directionIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4463D5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.explore_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            '${normalizedHeading.toStringAsFixed(0)}° $cardinal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordinatesCard extends StatelessWidget {
  const _CoordinatesCard({required this.position});

  final LatLng position;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x15FFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordenadas',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            '${position.latitude.toStringAsFixed(4)}, '
            '${position.longitude.toStringAsFixed(4)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WeatherSummaryCard extends StatelessWidget {
  const _WeatherSummaryCard({required this.region});

  final RegionWeatherModel region;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = region.isNearby
        ? const Color(0xFF26A69A)
        : const Color(0xFF7693FF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF05051F).withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              region.weatherIcon,
              color: region.iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        region.regionName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        '${region.proximityLabel} • ${region.distanceLabel}',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${region.description} • Umidade ${region.humidity}% • '
                  'Vento ${region.windSpeedKmh.round()} km/h',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${region.temperature.round()}°C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
