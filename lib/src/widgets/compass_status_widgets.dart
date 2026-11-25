import 'package:flutter/material.dart';

class CompassLoadingWidget extends StatelessWidget {
  const CompassLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF7693FF)),
          SizedBox(height: 16),
          Text(
            'Obtendo localização, bússola e clima...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class CompassErrorWidget extends StatelessWidget {
  const CompassErrorWidget({
    required this.errorMessage,
    required this.onRetry,
    this.onExploreWithoutGps,
    super.key,
  });

  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback? onExploreWithoutGps;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: const Color(0x15FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: Color(0xFF7693FF),
                size: 52,
              ),
              const SizedBox(height: 16),
              const Text(
                'Localização indisponível',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7693FF),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Tentar novamente',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (onExploreWithoutGps != null)
                    OutlinedButton.icon(
                      onPressed: onExploreWithoutGps,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Explorar mapa'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
