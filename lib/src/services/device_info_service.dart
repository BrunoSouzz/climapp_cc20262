import 'package:flutter/services.dart';

/// Resultado da consulta do país do dispositivo via MethodChannel nativo.
class DeviceCountryResult {
  const DeviceCountryResult({
    required this.countryCode,
    required this.isAvailable,
    this.errorMessage,
  });

  final String countryCode;
  final bool isAvailable;
  final String? errorMessage;

  String get displayLabel {
    if (!isAvailable) {
      return errorMessage ?? 'Não foi possível identificar o país.';
    }
    final name = DeviceInfoService.countryNameFromCode(countryCode);
    return name != null ? '$countryCode ($name)' : countryCode;
  }
}

/// Serviço responsável por obter informações nativas do dispositivo via MethodChannel.
class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel(
    'br.dev.yago.climapp/device',
  );

  static const String _fallbackCountry = 'Não identificado';

  static const Map<String, String> _countryNames = {
    'BR': 'Brasil',
    'US': 'Estados Unidos',
    'PT': 'Portugal',
    'AR': 'Argentina',
    'CL': 'Chile',
    'UY': 'Uruguai',
    'PY': 'Paraguai',
    'CO': 'Colômbia',
    'MX': 'México',
    'CA': 'Canadá',
    'GB': 'Reino Unido',
    'ES': 'Espanha',
    'FR': 'França',
    'DE': 'Alemanha',
    'IT': 'Itália',
    'JP': 'Japão',
  };

  static String? countryNameFromCode(String code) {
    return _countryNames[code.trim().toUpperCase()];
  }

  /// Obtém o código do país do dispositivo pelo canal nativo.
  /// Em caso de indisponibilidade, retorna uma mensagem amigável sem lançar erro.
  Future<DeviceCountryResult> getDeviceCountryDetails() async {
    try {
      final String? countryCode = await _channel.invokeMethod<String>(
        'getDeviceCountry',
      );
      final normalized = countryCode?.trim().toUpperCase() ?? '';
      if (normalized.isEmpty) {
        return const DeviceCountryResult(
          countryCode: _fallbackCountry,
          isAvailable: false,
          errorMessage: 'País do dispositivo indisponível no momento.',
        );
      }
      return DeviceCountryResult(
        countryCode: normalized,
        isAvailable: true,
      );
    } on MissingPluginException {
      return const DeviceCountryResult(
        countryCode: _fallbackCountry,
        isAvailable: false,
        errorMessage: 'Recurso nativo não disponível nesta plataforma.',
      );
    } on PlatformException catch (e) {
      return DeviceCountryResult(
        countryCode: _fallbackCountry,
        isAvailable: false,
        errorMessage:
            e.message ?? 'Não foi possível obter o país do dispositivo.',
      );
    }
  }

  /// Mantém compatibilidade direta retornando a string do país ou fallback amigável.
  Future<String> getDeviceCountry() async {
    final result = await getDeviceCountryDetails();
    return result.countryCode;
  }
}
