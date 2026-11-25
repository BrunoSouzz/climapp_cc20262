import 'package:climapp_cc20262/src/models/region_weather_model.dart';
import 'package:climapp_cc20262/src/services/location_service.dart';
import 'package:climapp_cc20262/src/services/weather_service.dart';
import 'package:climapp_cc20262/src/widgets/compass_info_panel_widget.dart';
import 'package:climapp_cc20262/src/widgets/compass_status_widgets.dart';
import 'package:climapp_cc20262/src/widgets/compass_user_marker_widget.dart';
import 'package:climapp_cc20262/src/widgets/floating_compass_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum RegionProximityFilter { all, nearby, far }

class _ReferenceRegion {
  const _ReferenceRegion(this.name, this.position);

  final String name;
  final LatLng position;
}

class CompassMapScreen extends StatefulWidget {
  const CompassMapScreen({super.key});

  @override
  State<CompassMapScreen> createState() => _CompassMapScreenState();
}

class _CompassMapScreenState extends State<CompassMapScreen> {
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter = LatLng(-10.9472, -37.0731);

  static const List<_ReferenceRegion> _distantReferenceCities = [
    _ReferenceRegion('Aracaju, SE', LatLng(-10.9472, -37.0731)),
    _ReferenceRegion('Salvador, BA', LatLng(-12.9714, -38.5014)),
    _ReferenceRegion('Recife, PE', LatLng(-8.0476, -34.8770)),
    _ReferenceRegion('Brasília, DF', LatLng(-15.7975, -47.8919)),
    _ReferenceRegion('São Paulo, SP', LatLng(-23.5505, -46.6333)),
    _ReferenceRegion('Rio de Janeiro, RJ', LatLng(-22.9068, -43.1729)),
    _ReferenceRegion('Curitiba, PR', LatLng(-25.4284, -49.2733)),
    _ReferenceRegion('Manaus, AM', LatLng(-3.1190, -60.0217)),
  ];

  LatLng? _userPosition;
  LatLng _mapCenter = _defaultCenter;
  bool _hasGpsPosition = false;
  bool _isLoading = true;
  bool _isLoadingWeather = false;
  bool _isFetchingTappedRegion = false;
  String? _errorMessage;

  RegionProximityFilter _filter = RegionProximityFilter.all;
  List<RegionWeatherModel> _regions = [];
  RegionWeatherModel? _selectedRegion;

  @override
  void initState() {
    super.initState();
    _loadLocationAndWeather();
  }

  Future<void> _loadLocationAndWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.determinePosition();
      if (!mounted) return;

      setState(() {
        _userPosition = position;
        _mapCenter = position;
        _hasGpsPosition = true;
        _isLoading = false;
      });

      await _loadNearbyAndDistantWeather(position, hasGps: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _exploreWithoutGps() async {
    setState(() {
      _errorMessage = null;
      _userPosition = null;
      _mapCenter = _defaultCenter;
      _hasGpsPosition = false;
      _isLoading = false;
    });
    await _loadNearbyAndDistantWeather(_defaultCenter, hasGps: false);
  }

  Future<void> _loadNearbyAndDistantWeather(
    LatLng origin, {
    required bool hasGps,
  }) async {
    setState(() => _isLoadingWeather = true);

    final List<Future<RegionWeatherModel?>> tasks = [];

    // 1. Ponto principal (posição atual ou centro padrão)
    final String originName = hasGps
        ? await _locationService.getRegionName(
            origin.latitude,
            origin.longitude,
          )
        : 'Aracaju, SE';

    tasks.add(
      _weatherService.getRegionWeather(
        id: 'origin',
        position: origin,
        distanceKm: 0,
        regionName: originName,
        isUserLocation: hasGps,
      ),
    );

    // 2. Pontos próximos (ao redor da posição atual: Norte, Leste, Sul, Oeste)
    const nearbyOffsets = [
      ('Região Norte próxima', 0.08, 0.0),
      ('Região Leste próxima', 0.0, 0.08),
      ('Região Sul próxima', -0.10, -0.04),
      ('Região Oeste próxima', 0.04, -0.10),
    ];

    for (var i = 0; i < nearbyOffsets.length; i++) {
      final (fallbackLabel, dLat, dLon) = nearbyOffsets[i];
      final target = LatLng(origin.latitude + dLat, origin.longitude + dLon);
      final double distanceKm = _locationService.calculateDistanceKm(
        origin,
        target,
      );
      tasks.add(() async {
        final geocodedName = await _locationService.getRegionName(
          target.latitude,
          target.longitude,
        );
        final finalName = geocodedName == 'Região próxima'
            ? fallbackLabel
            : geocodedName;
        return _weatherService.getRegionWeather(
          id: 'nearby_$i',
          position: target,
          distanceKm: distanceKm,
          regionName: finalName,
        );
      }());
    }

    // 3. Regiões distantes em todo o país
    for (final city in _distantReferenceCities) {
      final double distanceKm = _locationService.calculateDistanceKm(
        origin,
        city.position,
      );
      // Evita duplicar uma cidade distante caso o usuário já esteja nela
      if (distanceKm < 25) continue;

      tasks.add(
        _weatherService.getRegionWeather(
          id: 'far_${city.name}',
          position: city.position,
          distanceKm: distanceKm,
          regionName: city.name,
        ),
      );
    }

    final results = await Future.wait(tasks);
    if (!mounted) return;

    final loaded = results.whereType<RegionWeatherModel>().toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    setState(() {
      _regions = loaded;
      _selectedRegion = loaded.isNotEmpty ? loaded.first : null;
      _isLoadingWeather = false;
    });
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng tappedPoint) async {
    setState(() => _isFetchingTappedRegion = true);

    final double distanceKm = _locationService.calculateDistanceKm(
      _mapCenter,
      tappedPoint,
    );
    final String regionName = await _locationService.getRegionName(
      tappedPoint.latitude,
      tappedPoint.longitude,
    );

    final RegionWeatherModel? weather = await _weatherService.getRegionWeather(
      id: 'custom_${tappedPoint.latitude.toStringAsFixed(3)}_${tappedPoint.longitude.toStringAsFixed(3)}',
      position: tappedPoint,
      distanceKm: distanceKm,
      regionName: regionName,
      isCustomPin: true,
    );

    if (!mounted) return;

    setState(() {
      _isFetchingTappedRegion = false;
      if (weather != null) {
        _regions.removeWhere((item) => item.isCustomPin);
        _regions.add(weather);
        _selectedRegion = weather;
      }
    });
  }

  List<RegionWeatherModel> get _visibleRegions {
    switch (_filter) {
      case RegionProximityFilter.nearby:
        return _regions.where((r) => r.isNearby).toList();
      case RegionProximityFilter.far:
        return _regions.where((r) => !r.isNearby).toList();
      case RegionProximityFilter.all:
        return _regions;
    }
  }

  void _applyFilter(RegionProximityFilter filter) {
    setState(() => _filter = filter);

    if (filter == RegionProximityFilter.nearby) {
      _mapController.move(_mapCenter, 11.5);
    } else if (filter == RegionProximityFilter.far) {
      _mapController.move(const LatLng(-14.2350, -49.5000), 4.2);
    } else {
      _mapController.move(_mapCenter, 9.0);
    }
  }

  void _focusRegion(RegionWeatherModel region) {
    setState(() => _selectedRegion = region);
    _mapController.move(region.position, region.isNearby ? 12.5 : 8.5);
  }

  void _recenterMap() {
    _mapController.move(_mapCenter, 14.0);
    _mapController.rotate(0.0);
  }

  void _resetNorth() {
    _mapController.rotate(0.0);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(3.0, 18.0);
    _mapController.move(camera.center, nextZoom);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05051F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00457D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Mapa Climático & Bússola',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (!_isLoading && _errorMessage == null)
            IconButton(
              onPressed: () => _loadNearbyAndDistantWeather(
                _mapCenter,
                hasGps: _hasGpsPosition,
              ),
              tooltip: 'Atualizar clima no mapa',
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF00457D), Color(0xFF05051F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const CompassLoadingWidget()
            : _errorMessage != null
            ? CompassErrorWidget(
                errorMessage: _errorMessage!,
                onRetry: _loadLocationAndWeather,
                onExploreWithoutGps: _exploreWithoutGps,
              )
            : _buildMapContent(),
      ),
    );
  }

  Widget _buildMapContent() {
    final visibleRegions = _visibleRegions;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events ?? const Stream<CompassEvent>.empty(),
      builder: (context, snapshot) {
        final double heading = snapshot.hasError
            ? 0.0
            : (snapshot.data?.heading ?? 0.0);

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 12.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'br.dev.yago.climapp_cc20262',
                ),
                if (_hasGpsPosition && _userPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _userPosition!,
                        radius: 250,
                        useRadiusInMeter: true,
                        color: const Color(0xFF4463D5).withValues(alpha: 0.16),
                        borderColor: const Color(
                          0xFF7693FF,
                        ).withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ...visibleRegions.map((region) {
                      final bool isSelected = _selectedRegion?.id == region.id;
                      return Marker(
                        point: region.position,
                        width: 136,
                        height: 54,
                        alignment: Alignment.topCenter,
                        child: _WeatherMapPin(
                          region: region,
                          isSelected: isSelected,
                          onTap: () => _focusRegion(region),
                        ),
                      );
                    }),
                    if (_hasGpsPosition && _userPosition != null)
                      Marker(
                        point: _userPosition!,
                        width: 56,
                        height: 56,
                        child: CompassUserMarkerWidget(heading: heading),
                      ),
                  ],
                ),
              ],
            ),

            // Barra superior estilo Google Maps: filtro Perto / Longe + instrução
            Positioned(
              top: 12,
              left: 12,
              right: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterPill(
                          label: 'Todas',
                          icon: Icons.public,
                          selected: _filter == RegionProximityFilter.all,
                          onTap: () => _applyFilter(RegionProximityFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Perto',
                          icon: Icons.near_me_rounded,
                          selected: _filter == RegionProximityFilter.nearby,
                          onTap: () =>
                              _applyFilter(RegionProximityFilter.nearby),
                        ),
                        const SizedBox(width: 8),
                        _FilterPill(
                          label: 'Longe',
                          icon: Icons.travel_explore_rounded,
                          selected: _filter == RegionProximityFilter.far,
                          onTap: () => _applyFilter(RegionProximityFilter.far),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05051F).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingWeather) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7693FF),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            _isLoadingWeather
                                ? 'Carregando clima das regiões...'
                                : 'Toque no mapa para ver o clima em qualquer ponto',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controles laterais estilo Google Maps (bússola, zoom +, zoom -, centralizar)
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  FloatingCompassWidget(heading: heading, onTap: _resetNorth),
                  const SizedBox(height: 10),
                  _MapActionButton(
                    icon: Icons.add,
                    tooltip: 'Aproximar zoom',
                    onPressed: () => _zoomBy(1.2),
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.remove,
                    tooltip: 'Afastar zoom',
                    onPressed: () => _zoomBy(-1.2),
                  ),
                  const SizedBox(height: 6),
                  _MapActionButton(
                    icon: Icons.my_location,
                    tooltip: 'Minha localização',
                    onPressed: _recenterMap,
                  ),
                ],
              ),
            ),

            // Carrossel de regiões + painel inferior com bússola e clima
            Positioned(
              bottom: 14,
              left: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (visibleRegions.isNotEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: visibleRegions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final region = visibleRegions[index];
                          final bool selected =
                              _selectedRegion?.id == region.id;
                          return ActionChip(
                            onPressed: () => _focusRegion(region),
                            backgroundColor: selected
                                ? const Color(0xFF4463D5)
                                : const Color(
                                    0xFF05051F,
                                  ).withValues(alpha: 0.9),
                            side: BorderSide(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF7693FF),
                            ),
                            avatar: Icon(
                              region.weatherIcon,
                              size: 16,
                              color: region.iconColor,
                            ),
                            label: Text(
                              '${region.regionName} • ${region.temperature.round()}°C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  CompassInfoPanelWidget(
                    position: _mapCenter,
                    heading: heading,
                    selectedRegion: _selectedRegion,
                    isFetchingRegionWeather: _isFetchingTappedRegion,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeatherMapPin extends StatelessWidget {
  const _WeatherMapPin({
    required this.region,
    required this.isSelected,
    required this.onTap,
  });

  final RegionWeatherModel region;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isSelected
        ? Colors.amberAccent
        : (region.isNearby
              ? const Color(0xFF26A69A)
              : const Color(0xFF7693FF));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00457D)
                  : const Color(0xFF05051F).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(region.weatherIcon, color: region.iconColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${region.temperature.round()}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    region.regionName.split(',').first,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_drop_down, color: borderColor, size: 16),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF4463D5)
          : const Color(0xFF05051F).withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? Colors.white : const Color(0xFF7693FF),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF05051F).withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
