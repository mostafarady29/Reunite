import 'package:flutter/material.dart';

import '../../../../../../core/services/location_service.dart';
import '../../../../../../features/reports/data/repositories/child_case_repository.dart';
import '../../../../../../features/reports/domain/child_case.dart';
import 'sections/emergency_section.dart';
import 'sections/nearby_section.dart';
import 'sections/stats_section.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.emergency,
    required this.nearby,
    required this.stats,
    this.userLocation,
  });

  final List<ChildCase> emergency;
  final List<ChildCase> nearby;
  final CaseStatistics stats;
  final LatLng? userLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatsSection(stats: stats),
          const SizedBox(height: 28),
          EmergencySection(emergency: emergency, userLocation: userLocation),
          const SizedBox(height: 28),
          NearbySection(nearby: nearby, hasLocation: userLocation != null),
        ],
      ),
    );
  }
}
