import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Dados meteorológicos de um ponto/região exibido no mapa interativo.
class RegionWeatherModel {
  const RegionWeatherModel({
    required this.id,
    required this.regionName,
    required this.position,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.windSpeedKmh,
    required this.conditionType,
    required this.distanceKm,
    required this.isNearby,
    this.isUserLocation = false,
    this.isCustomPin = false,
    this.source = 'Open-Meteo',
  });

  final String id;
  final String regionName;
  final LatLng position;
  final double temperature;
  final String description;
  final int humidity;
  final double windSpeedKmh;
  final String conditionType;
  final double distanceKm;
  final bool isNearby;
  final bool isUserLocation;
  final bool isCustomPin;
  final String source;

  IconData get weatherIcon {
    switch (conditionType) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'partly_cloudy':
        return Icons.wb_cloudy_rounded;
      case 'cloudy':
        return Icons.cloud_rounded;
      case 'drizzle':
        return Icons.grain_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'storm':
        return Icons.thunderstorm_rounded;
      case 'fog':
        return Icons.foggy;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.thermostat_rounded;
    }
  }

  Color get iconColor {
    switch (conditionType) {
      case 'clear':
        return Colors.amberAccent;
      case 'partly_cloudy':
        return Colors.lightBlueAccent;
      case 'cloudy':
        return Colors.white70;
      case 'drizzle':
      case 'rain':
        return Colors.cyanAccent;
      case 'storm':
        return Colors.deepOrangeAccent;
      case 'fog':
        return Colors.blueGrey.shade200;
      case 'snow':
        return Colors.lightBlue.shade100;
      default:
        return Colors.white;
    }
  }

  String get distanceLabel {
    if (isUserLocation || distanceKm < 0.5) {
      return 'Sua região';
    }
    if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    return '${distanceKm.round()} km';
  }

  String get proximityLabel => isNearby ? 'Perto' : 'Longe';

  factory RegionWeatherModel.fromOpenWeatherJson(
    Map<String, dynamic> json, {
    required String id,
    required LatLng position,
    required double distanceKm,
    String? fallbackName,
    bool isUserLocation = false,
    bool isCustomPin = false,
  }) {
    final mainData = (json['main'] as Map<String, dynamic>?) ?? {};
    final windData = (json['wind'] as Map<String, dynamic>?) ?? {};
    final weatherList = (json['weather'] as List?) ?? const [];
    final firstWeather = weatherList.isNotEmpty
        ? (weatherList.first as Map<String, dynamic>)
        : <String, dynamic>{};

    final int weatherId = (firstWeather['id'] as num?)?.toInt() ?? 800;
    final String rawDesc =
        firstWeather['description']?.toString().trim() ?? 'Clima atual';
    final String description = rawDesc.isNotEmpty
        ? '${rawDesc[0].toUpperCase()}${rawDesc.substring(1)}'
        : 'Clima atual';

    final String apiName = json['name']?.toString().trim() ?? '';
    final String regionName = apiName.isNotEmpty
        ? apiName
        : (fallbackName ?? 'Região selecionada');

    final double windMs = (windData['speed'] as num?)?.toDouble() ?? 0.0;

    return RegionWeatherModel(
      id: id,
      regionName: regionName,
      position: position,
      temperature: (mainData['temp'] as num?)?.toDouble() ?? 0.0,
      description: description,
      humidity: (mainData['humidity'] as num?)?.toInt() ?? 0,
      windSpeedKmh: windMs * 3.6,
      conditionType: _conditionFromOpenWeatherId(weatherId),
      distanceKm: distanceKm,
      isNearby: distanceKm <= 50.0,
      isUserLocation: isUserLocation,
      isCustomPin: isCustomPin,
      source: 'OpenWeather',
    );
  }

  factory RegionWeatherModel.fromOpenMeteoJson(
    Map<String, dynamic> json, {
    required String id,
    required String regionName,
    required LatLng position,
    required double distanceKm,
    bool isUserLocation = false,
    bool isCustomPin = false,
  }) {
    final current = (json['current'] as Map<String, dynamic>?) ?? {};
    final int code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final (String type, String desc) = _mapWmoCode(code);

    return RegionWeatherModel(
      id: id,
      regionName: regionName,
      position: position,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      description: desc,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      conditionType: type,
      distanceKm: distanceKm,
      isNearby: distanceKm <= 50.0,
      isUserLocation: isUserLocation,
      isCustomPin: isCustomPin,
      source: 'Open-Meteo',
    );
  }

  static String _conditionFromOpenWeatherId(int id) {
    if (id >= 200 && id < 300) return 'storm';
    if (id >= 300 && id < 400) return 'drizzle';
    if (id >= 500 && id < 600) return 'rain';
    if (id >= 600 && id < 700) return 'snow';
    if (id >= 700 && id < 800) return 'fog';
    if (id == 800) return 'clear';
    if (id == 801 || id == 802) return 'partly_cloudy';
    return 'cloudy';
  }

  static (String, String) _mapWmoCode(int code) {
    switch (code) {
      case 0:
        return ('clear', 'Céu limpo');
      case 1:
      case 2:
        return ('partly_cloudy', 'Parcialmente nublado');
      case 3:
        return ('cloudy', 'Nublado');
      case 45:
      case 48:
        return ('fog', 'Neblina');
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return ('drizzle', 'Garoa');
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return ('rain', 'Chuva');
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return ('snow', 'Neve');
      case 95:
      case 96:
      case 99:
        return ('storm', 'Tempestade');
      default:
        return ('partly_cloudy', 'Tempo variável');
    }
  }
}
