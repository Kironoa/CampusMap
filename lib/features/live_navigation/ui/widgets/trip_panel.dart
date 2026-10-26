// lib/features/live_navigation/ui/widgets/trip_panel.dart
//
// Bottom trip panel: ETA, remaining distance/time, route options, controls.
import 'package:flutter/material.dart';

import '../../models/nav_route.dart';
import '../../models/navigation_state.dart';
import '../../config/nav_theme.dart';
import '../nav_format.dart';

class TripPanel extends StatelessWidget {
  const TripPanel({
    super.key,
    required this.phase,
    required this.options,
    required this.selectedIndex,
    required this.progress,
    required this.isLoadingRoute,
    required this.onSelectOption,
    required this.onStart,
    required this.onStop,
  });

  final NavPhase phase;
  final List<NavRouteOption> options;
  final int selectedIndex;
  final TripProgress? progress;
  final bool isLoadingRoute;
  final void Function(int index) onSelectOption;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            if (phase == NavPhase.navigating && progress != null)
              _buildNavigating(context)
            else
              _buildPreview(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigating(BuildContext context) {
    final p = progress!;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: NavTheme.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.directions_walk,
            color: NavTheme.accent,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatEta(p.eta),
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NavTheme.accent,
                ),
              ),
              Text(
                p.arrived
                    ? 'Arrived at destination'
                    : '${formatDistance(p.remainingDistanceM)} remaining',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
          style: FilledButton.styleFrom(backgroundColor: NavTheme.stopButton),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (isLoadingRoute) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Finding routes…'),
          ],
        ),
      );
    }
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Search for a destination above to preview routes.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final option = options[index];
              final selected = index == selectedIndex;
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.summary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${formatDuration(option.durationSeconds)} • ${formatDistance(option.distanceMeters)}',
                    ),
                  ],
                ),
                selected: selected,
                selectedColor: NavTheme.accent.withValues(alpha: 0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected
                        ? NavTheme.accent
                        : Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) => onSelectOption(index),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.navigation),
            label: const Text('Start navigation'),
            style: FilledButton.styleFrom(
              backgroundColor: NavTheme.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}




