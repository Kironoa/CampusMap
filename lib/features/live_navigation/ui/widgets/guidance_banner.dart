// lib/features/live_navigation/ui/widgets/guidance_banner.dart
//
// Waze-style next-turn banner shown during active navigation.
import 'package:flutter/material.dart';

import '../../models/navigation_state.dart';
import '../../config/nav_theme.dart';
import '../nav_format.dart';

/// Maps maneuver labels to Material icons (best-effort).
IconData maneuverIcon(String maneuverLabel) {
  final label = maneuverLabel.toLowerCase();
  if (label.contains('left')) return Icons.turn_left;
  if (label.contains('right')) return Icons.turn_right;
  if (label.contains('u-turn') || label.contains('u turn')) {
    return Icons.u_turn_left;
  }
  if (label.contains('roundabout') || label.contains('rotary')) {
    return Icons.roundabout_left;
  }
  if (label.contains('exit')) return Icons.exit_to_app;
  if (label.contains('merge')) return Icons.merge;
  if (label.contains('ferry')) return Icons.directions_boat;
  return Icons.straight;
}

class GuidanceBanner extends StatelessWidget {
  const GuidanceBanner({
    super.key,
    required this.progress,
    required this.rerouting,
  });

  final TripProgress progress;
  final bool rerouting;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black.withValues(alpha: 0.3),
      color: NavTheme.banner,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NavTheme.bannerText.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                maneuverIcon(progress.maneuverLabel),
                color: NavTheme.bannerText,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rerouting ? 'Rerouting…' : progress.instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NavTheme.bannerText,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    progress.arrived
                        ? 'Arrived'
                        : 'In ${formatDistance(progress.distanceToManeuverM)}'
                              '${progress.offRoute ? ' • Off route' : ''}',
                    style: TextStyle(
                      color: NavTheme.bannerText.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





