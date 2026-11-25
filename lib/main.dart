import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/models/weather_forecast_model.dart';
import 'package:climapp_cc20262/src/screens/weather_city_screen.dart';
import 'package:climapp_cc20262/src/screens/welcome_screen.dart';
import 'package:climapp_cc20262/src/services/notification_service.dart';
import 'package:climapp_cc20262/src/widgets/nointernet_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background Handler ID: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // isOptional: não derruba o app se o .env não existir.
  // A falta da chave é tratada no controller (mensagem de erro na tela).
  await dotenv.load(fileName: '.env', isOptional: true);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notificações dependem de rede (token FCM). Se estiver offline, o app
  // não pode ficar travado na abertura: segue sem notificações.
  try {
    await NotificationService().initialize().timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Falha ao iniciar notificações (offline?): $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return MaterialApp(
      navigatorKey: notificationService.navigatorKey,
      scaffoldMessengerKey: notificationService.scaffoldMessengerKey,
      title: 'Climapp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // Texto branco: todas as telas usam fundo escuro/azul.
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/weather') {
          final args = settings.arguments;
          if (args is WeatherForecastModel) {
            return MaterialPageRoute(
              builder: (_) => WeatherCityScreen(weatherForecastModel: args),
            );
          }
          if (args is String && args.trim().isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => _WeatherRouteLoaderScreen(cityName: args.trim()),
            );
          }
        }
        return null;
      },
      home: const WelcomeScreen(),
    );
  }
}

/// Carrega os dados da cidade recebida via deep link de notificação push.
class _WeatherRouteLoaderScreen extends StatefulWidget {
  const _WeatherRouteLoaderScreen({required this.cityName});

  final String cityName;

  @override
  State<_WeatherRouteLoaderScreen> createState() =>
      _WeatherRouteLoaderScreenState();
}

class _WeatherRouteLoaderScreenState extends State<_WeatherRouteLoaderScreen> {
  late Future<WeatherForecastModel> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = ListCityController.fetchCityForecast(widget.cityName);
  }

  void _retry() {
    setState(() {
      _forecastFuture = ListCityController.fetchCityForecast(widget.cityName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherForecastModel>(
      future: _forecastFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF00457D),
              foregroundColor: Colors.white,
              title: Text(widget.cityName),
            ),
            body: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          final message = snapshot.error
              ?.toString()
              .replaceFirst('Exception: ', '');
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF00457D),
              foregroundColor: Colors.white,
              title: Text(widget.cityName),
            ),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: GenericErrorWidget(message: message, onRetry: _retry),
            ),
          );
        }

        return WeatherCityScreen(weatherForecastModel: snapshot.data!);
      },
    );
  }
}
