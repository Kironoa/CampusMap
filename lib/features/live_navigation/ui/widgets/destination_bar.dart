// lib/features/live_navigation/ui/widgets/destination_bar.dart
//
// Destination selection WITHOUT place search (no key, no account):
// tap the map to drop a pin, or enter coordinates manually.
// A [GeocodingProvider] implementation can later add text search here
// without touching routing or guidance.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/geo_math.dart';
import '../../models/navigation_state.dart';
import '../../config/nav_theme.dart';
import '../nav_format.dart';

class DestinationBar extends StatelessWidget {
  const DestinationBar({
    super.key,
    required this.destination,
    required this.onCoordinates,
    required this.onClear,
  });

  final NavDestination? destination;

  /// Called with validated coordinates from the manual entry dialog.
  final void Function(NavLatLng point) onCoordinates;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: destination == null
            ? Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NavTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.touch_app_outlined,
                      color: NavTheme.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Tap the map to set your destination',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.pin_drop_outlined),
                    tooltip: 'Enter coordinates',
                    onPressed: () => _showCoordinatesDialog(context),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NavTheme.pin.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: NavTheme.pin,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          destination!.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          formatLatLng(
                            destination!.location.latitude,
                            destination!.location.longitude,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_location_outlined),
                    tooltip: 'Enter coordinates',
                    onPressed: () => _showCoordinatesDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear destination',
                    onPressed: onClear,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _showCoordinatesDialog(BuildContext context) async {
    final latController = TextEditingController(
      text: destination?.location.latitude.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: destination?.location.longitude.toString() ?? '',
    );
    var error = '';
    final result = await showDialog<NavLatLng>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Destination coordinates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Latitude (-90 … 90)',
                ),
              ),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Longitude (-180 … 180)',
                ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final lat = double.tryParse(latController.text.trim());
                final lng = double.tryParse(lngController.text.trim());
                if (lat == null ||
                    lng == null ||
                    lat < -90 ||
                    lat > 90 ||
                    lng < -180 ||
                    lng > 180) {
                  setDialogState(() {
                    error = 'Enter a valid latitude and longitude.';
                  });
                  return;
                }
                Navigator.of(context).pop(NavLatLng(lat, lng));
              },
              child: const Text('Set destination'),
            ),
          ],
        ),
      ),
    );
    latController.dispose();
    lngController.dispose();
    if (result != null) onCoordinates(result);
  }
}


