import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../../features/reports/domain/child_case.dart';
import '../../../../../../features/shared/domain/app_enums.dart';

class EmergencyCarouselCard extends StatelessWidget {
  const EmergencyCarouselCard({super.key, required this.caseData, this.distanceLabel, this.onTap});
  final ChildCase caseData;
  final String? distanceLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.palette.border),
            boxShadow: [BoxShadow(color: context.palette.cardShadow, blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: SizedBox(
                      height: 124,
                      width: double.infinity,
                      child: ChildPhoto(seed: caseData.locality, imagePath: caseData.photoPath, size: 124, radius: 100),
                    ),
                  ),
                  if (distanceLabel != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(distanceLabel!, style: context.textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caseData.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      '${caseData.age} ${context.tr('missing.yearsOld')} • ${context.tr(caseData.gender.key)} • ${caseData.area}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: context.palette.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timeAgo(context, caseData.missingSince),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall?.copyWith(color: context.palette.textMuted, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(100)),
                          child: Text(context.tr('common.viewCase'), style: context.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String timeAgo(BuildContext context, DateTime since) {
    final mins = DateTime.now().difference(since).inMinutes;
    if (mins < 1) return context.tr('timeAgo.justNow');
    if (mins < 60) return context.tr('timeAgo.minutes', namedArgs: {'count': '$mins'});
    final hrs = (mins / 60).floor();
    if (hrs < 24) return context.tr('timeAgo.hours', namedArgs: {'count': '$hrs'});
    final days = (hrs / 24).floor();
    return context.tr('timeAgo.days', namedArgs: {'count': '$days'});
  }
}
