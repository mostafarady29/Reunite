import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../../core/router/app_router.dart';
import '../../../../../../../core/services/location_service.dart';
import '../../../../../../../core/theme/app_colors.dart';
import '../../../../../../../core/theme/app_dimens.dart';
import '../../../../../../../core/utils/distance_format.dart';
import '../../../../../../../features/reports/domain/child_case.dart';
import '../emergency_carousel_card.dart';
import '../modern_empty.dart';
import '../modern_section_header.dart';

class EmergencySection extends StatelessWidget {
  const EmergencySection({
    super.key,
    required this.emergency,
    this.userLocation,
  });
  final List<ChildCase> emergency;
  final LatLng? userLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
          child: ModernSectionHeader(
            icon: Icons.local_fire_department_rounded,
            iconBg: AppColors.emergency,
            title: context.tr('home.emergencyCases'),
            subtitle: context.tr('home.recentReports'),
            trailingLabel: context.tr('home.seeAll'),
            onTrailingTap: () => AutoTabsRouter.of(context).setActiveIndex(1),
          ),
        ),
        const SizedBox(height: 14),
        if (emergency.isEmpty)
          ModernEmpty(
            title: context.tr('home.emptyNearby'),
            subtitle: context.tr('home.emptyNearbySub'),
            icon: Icons.verified_user_outlined,
            color: AppColors.success,
          )
        else
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.xl),
              physics: const BouncingScrollPhysics(),
              itemCount: emergency.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final c = emergency[i];
                String? dist;
                if (userLocation != null && c.coordinates != null) {
                  final meters = userLocation!.distanceMetersTo(c.coordinates!);
                  dist = DistanceFormat.format(meters);
                }
                return EmergencyCarouselCard(
                  caseData: c,
                  distanceLabel: dist,
                  onTap: () => context.router.push(ChildDetailsRoute(caseId: c.id)),
                )
                    .animate()
                    .fadeIn(delay: (120 + i * 80).ms)
                    .slideX(begin: 0.12);
              },
            ),
          ),
      ],
    );
  }
}



