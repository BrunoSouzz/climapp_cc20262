import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/models/region_weather_model.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/screens/list_city_screen.dart';
import 'package:climapp_cc20262/src/services/device_info_service.dart';
import 'package:climapp_cc20262/src/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpClientRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  final HttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static final List<int> _svgBytes = utf8.encode(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"></svg>',
  );

  final HttpHeaders _headers = _FakeHttpHeaders();

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  HttpHeaders get headers => _headers;

  @override
  int get contentLength => _svgBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_svgBytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeListCityController extends ListCityController {
  _FakeListCityController({required DeviceCountryResult countryResult})
    : super(deviceInfoService: DeviceInfoService()) {
    deviceCountryResult = countryResult;
    status = LoadStatus.success;
    allCities = [
      WeatherForecastModel(
        temp: 28,
        date: '25/11',
        time: '12:00',
        conditionCode: '27',
        description: 'Ensolarado',
        currently: 'dia',
        city: 'Aracaju, SE',
        imgId: '27',
        humidity: 65,
        cloudiness: 10,
        rain: 0,
        windSpeedy: '12 km/h',
        windDirection: 90,
        windCardinal: 'L',
        sunrise: '05:10 am',
        sunset: '05:35 pm',
        moonPhase: 'full',
        conditionSlug: 'clear_day',
        cityName: 'Aracaju',
        timezone: '-03:00',
        forecast: const [],
      ),
    ];
    filteredCities = List.from(allCities);
  }

  @override
  void startMonitoring() {}

  @override
  Future<void> loadCities() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceInfoService MethodChannel', () {
    const channel = MethodChannel('br.dev.yago.climapp/device');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('retorna país do dispositivo quando canal nativo responde', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getDeviceCountry') return 'br';
            return null;
          });

      final service = DeviceInfoService();
      final result = await service.getDeviceCountryDetails();

      expect(result.isAvailable, isTrue);
      expect(result.countryCode, 'BR');
      expect(result.displayLabel, 'BR (Brasil)');
    });

    test('retorna fallback tranquilo em caso de PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: 'COUNTRY_UNAVAILABLE',
              message: 'Não foi possível identificar o país do dispositivo.',
            );
          });

      final service = DeviceInfoService();
      final result = await service.getDeviceCountryDetails();

      expect(result.isAvailable, isFalse);
      expect(result.countryCode, 'Não identificado');
      expect(
        result.displayLabel,
        'Não foi possível identificar o país do dispositivo.',
      );
    });
  });

  group('RegionWeatherModel', () {
    test('interpreta resposta Open-Meteo e diferencia perto/longe', () {
      final nearby = RegionWeatherModel.fromOpenMeteoJson(
        {
          'current': {
            'temperature_2m': 29.4,
            'relative_humidity_2m': 68,
            'weather_code': 0,
            'wind_speed_10m': 14.2,
          },
        },
        id: 'near_1',
        regionName: 'Aracaju, SE',
        position: const LatLng(-10.9472, -37.0731),
        distanceKm: 4.5,
      );

      final far = RegionWeatherModel.fromOpenMeteoJson(
        {
          'current': {
            'temperature_2m': 19.0,
            'relative_humidity_2m': 80,
            'weather_code': 61,
            'wind_speed_10m': 22.0,
          },
        },
        id: 'far_1',
        regionName: 'Curitiba, PR',
        position: const LatLng(-25.4284, -49.2733),
        distanceKm: 2050,
      );

      expect(nearby.isNearby, isTrue);
      expect(nearby.proximityLabel, 'Perto');
      expect(nearby.description, 'Céu limpo');

      expect(far.isNearby, isFalse);
      expect(far.proximityLabel, 'Longe');
      expect(far.description, 'Chuva');
      expect(far.distanceLabel, '2050 km');
    });
  });

  group('UI: ListCityScreen e Notificações em Foreground', () {
    testWidgets('exibe país do dispositivo e botão de mapa', (tester) async {
      await HttpOverrides.runZoned(() async {
        final fakeController = _FakeListCityController(
          countryResult: const DeviceCountryResult(
            countryCode: 'BR',
            isAvailable: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: ListCityScreen(controller: fakeController)),
        );
        await tester.pump();

        expect(find.text('País do dispositivo: BR (Brasil)'), findsOneWidget);
        expect(find.text('Aracaju'), findsOneWidget);
        expect(find.text('Ver mapa'), findsOneWidget);
      }, createHttpClient: (_) => _FakeHttpClient());
    });

    testWidgets('exibe mensagem tranquila quando país não está disponível', (
      tester,
    ) async {
      await HttpOverrides.runZoned(() async {
        final fakeController = _FakeListCityController(
          countryResult: const DeviceCountryResult(
            countryCode: 'Não identificado',
            isAvailable: false,
            errorMessage: 'País do dispositivo indisponível no momento.',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: ListCityScreen(controller: fakeController)),
        );
        await tester.pump();

        expect(
          find.text(
            'País do dispositivo: País do dispositivo indisponível no momento.',
          ),
          findsOneWidget,
        );
      }, createHttpClient: (_) => _FakeHttpClient());
    });

    testWidgets('exibe notificação push em foreground via SnackBar', (
      tester,
    ) async {
      final notificationService = NotificationService();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: notificationService.navigatorKey,
          scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      const message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Alerta de Chuva',
          body: 'Chuva moderada prevista para Aracaju.',
        ),
        data: {'city': 'Aracaju,SE'},
      );

      notificationService.handleForegroundMessage(message);
      await tester.pump();

      expect(find.text('Alerta de Chuva'), findsOneWidget);
      expect(
        find.text('Chuva moderada prevista para Aracaju.'),
        findsOneWidget,
      );
      expect(find.text('Ver clima'), findsOneWidget);
    });
  });
}
