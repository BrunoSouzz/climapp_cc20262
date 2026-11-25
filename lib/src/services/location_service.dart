import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'O serviço de localização (GPS) está desativado. Ative-o para ver sua posição no mapa.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Permissão de localização não concedida. Você pode tentar novamente quando preferir.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização bloqueada nas configurações do aparelho. Ative-a nas configurações para usar o GPS.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Obtém a coordenada atual pronta para uso no mapa.
  Future<LatLng> determinePosition() async {
    final position = await getCurrentPosition();
    if (position == null) {
      throw Exception('Não foi possível obter sua localização no momento.');
    }
    return LatLng(position.latitude, position.longitude);
  }

  /// Calcula a distância em quilômetros entre duas coordenadas.
  double calculateDistanceKm(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ) /
        1000.0;
  }

  /// Converte a Latitude e Longitude no nome da região (Ex: Aracaju, SE).
  Future<String> getRegionName(double latitude, double longitude) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String city =
            (place.subAdministrativeArea?.isNotEmpty == true
                ? place.subAdministrativeArea
                : place.locality) ??
            'Região próxima';
        final String state = place.administrativeArea ?? '';
        if (state.isNotEmpty && city != state) {
          return '$city, $state';
        }
        return city;
      }
    } catch (e) {
      debugPrint('Erro no Geocoding: $e');
    }
    return 'Região próxima';
  }

  /// Obtém o país via geocoding reverso das coordenadas, com fallback tranquilo.
  Future<String> getCountryFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String? country = place.country;
        final String? iso = place.isoCountryCode;
        if (country != null && country.isNotEmpty) {
          return iso != null && iso.isNotEmpty ? '$iso ($country)' : country;
        }
        if (iso != null && iso.isNotEmpty) {
          return iso;
        }
      }
    } catch (e) {
      debugPrint('Erro ao obter país via Geocoding: $e');
    }
    return 'País não identificado';
  }
}
