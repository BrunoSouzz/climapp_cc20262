import 'package:climapp_cc20262/src/controller/list_city_controller.dart';
import 'package:climapp_cc20262/src/screens/compass_map_screen.dart';
import 'package:climapp_cc20262/src/screens/weather_city_screen.dart';
import 'package:climapp_cc20262/src/widgets/city_tile_widget.dart';
import 'package:climapp_cc20262/src/widgets/nointernet_widget.dart';
import 'package:flutter/material.dart';

class ListCityScreen extends StatefulWidget {
  const ListCityScreen({this.controller, super.key});

  final ListCityController? controller;

  @override
  State<ListCityScreen> createState() => _ListCityScreenState();
}

class _ListCityScreenState extends State<ListCityScreen> {
  final TextEditingController textController = TextEditingController();
  late final ListCityController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    controller = widget.controller ?? ListCityController();
    controller.startMonitoring();
    controller.loadCities();
  }

  @override
  void dispose() {
    textController.dispose();
    if (_ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7693FF),
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CompassMapScreen()),
          );
        },
        label: const Text(
          'Ver mapa',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.explore),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              // Tela de erro ocupa a página inteira (sem campo de busca).
              if (controller.status == LoadStatus.noInternet) {
                return NoInternetWidget(onRetry: controller.loadCities);
              }
              if (controller.status == LoadStatus.error) {
                return GenericErrorWidget(
                  message: controller.errorMessage,
                  onRetry: controller.loadCities,
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 9),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      controller: textController,
                      onChanged: controller.filterCities,
                      decoration: const InputDecoration(
                        fillColor: Color(0x15FFFFFF),
                        filled: true,
                        hintText: 'Digite uma cidade',
                        hintStyle: TextStyle(color: Colors.white),
                        suffixIcon: Icon(Icons.search, color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DeviceCountryBanner(controller: controller),
                    const SizedBox(height: 10),
                    Expanded(child: _buildList()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.filteredCities.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma cidade encontrada',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: controller.filteredCities.length,
      itemBuilder: (context, index) {
        final city = controller.filteredCities[index];
        return CityTileWidget(
          cityName: city.cityName,
          icon: city.conditionSlug,
          temperature: city.temp,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WeatherCityScreen(weatherForecastModel: city),
              ),
            );
          },
        );
      },
    );
  }
}

class _DeviceCountryBanner extends StatelessWidget {
  const _DeviceCountryBanner({required this.controller});

  final ListCityController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.deviceCountryResult;
    final String label = result == null
        ? 'Identificando país do dispositivo...'
        : 'País do dispositivo: ${result.displayLabel}';
    final bool available = result?.isAvailable ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x15FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: available
              ? const Color(0xFF7693FF).withValues(alpha: 0.45)
              : Colors.white24,
        ),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.public : Icons.info_outline_rounded,
            color: available ? const Color(0xFF7693FF) : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: available ? Colors.white : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
