import 'dart:convert';

import 'package:climapp_cc20262/src/models/region_weather_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WeatherService {
  WeatherService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const Duration _timeout = Duration(seconds: 8);

  String get apiKey => dotenv.maybeGet('OPENWEATHER_API_KEY') ?? '';

  Future<Map<String, dynamic>?> getWeatherByCoordinates(
    double lat,
    double lon,
  ) async {
    if (apiKey.isEmpty) return null;

    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=pt_br',
    );

    try {
      final response = await _httpClient.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do clima (OpenWeather): $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getOpenMeteoByCoordinates(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
      '&timezone=auto',
    );

    try {
      final response = await _httpClient.get(url).timeout(_timeout);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do clima (Open-Meteo): $e');
    }
    return null;
  }

  /// Busca o clima para uma coordenada usando OpenWeather (se configurada)
  /// com fallback automático para Open-Meteo (sem necessidade de chave).
  Future<RegionWeatherModel?> getRegionWeather({
    required String id,
    required LatLng position,
    required double distanceKm,
    String? regionName,
    bool isUserLocation = false,
    bool isCustomPin = false,
  }) async {
    final openWeatherData = await getWeatherByCoordinates(
      position.latitude,
      position.longitude,
    );
    if (openWeatherData != null) {
      return RegionWeatherModel.fromOpenWeatherJson(
        openWeatherData,
        id: id,
        position: position,
        distanceKm: distanceKm,
        fallbackName: regionName,
        isUserLocation: isUserLocation,
        isCustomPin: isCustomPin,
      );
    }

    final openMeteoData = await getOpenMeteoByCoordinates(
      position.latitude,
      position.longitude,
    );
    if (openMeteoData != null) {
      return RegionWeatherModel.fromOpenMeteoJson(
        openMeteoData,
        id: id,
        regionName: regionName ?? 'Região selecionada',
        position: position,
        distanceKm: distanceKm,
        isUserLocation: isUserLocation,
        isCustomPin: isCustomPin,
      );
    }

    return null;
  }
}
