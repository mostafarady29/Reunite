import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../theme/app_colors.dart';
import '../utils/context_extensions.dart';
import '../../features/reports/domain/child_case.dart';
import '../../features/shared/domain/app_enums.dart';
import 'child_photo.dart';

/// ── Modern minimal Child Case Card ────────────────────────────────────────
/// Clean, airy, no urgent markers — focus on photo + name + location.
class ChildCaseCard extends StatelessWidget {
  const ChildCaseCard({super.key, required this.caseData, this.onTap, this.isFound = false, this.distanceLabel});
  final ChildCase caseData;
  final VoidCallback? onTap;
  final bool isFound;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.palette.border.withValues(alpha: 0.85)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo — clean rounded square, no urgent dot
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(width: 76, height: 76, child: ChildPhoto(seed: caseData.locality, imagePath: caseData.photoPath, size: 76, radius: 0, borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(width: 13),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name — single line, no badge
                    Text(caseData.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 14.5, height: 1.2)),
                    const SizedBox(height: 3),
                    Text('${caseData.age} ${context.tr('missing.yearsOld')}  •  ${context.tr(caseData.gender.key)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 12.5, height: 1.3)),
                    const SizedBox(height: 7),
                    Row(children: [
                      Icon(Icons.location_on_rounded, size: 13, color: context.palette.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          caseData.area.isNotEmpty
                              ? caseData.area
                              : (caseData.lastKnownLocation.isNotEmpty ? caseData.lastKnownLocation : caseData.city),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(color: context.palette.textMuted, fontSize: 12),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(isFound ? Icons.verified_outlined : Icons.access_time_rounded, size: 13, color: context.palette.textMuted),
                        const SizedBox(width: 3),
                        Expanded(child: Text(isFound ? context.tr('status.found') : _timeAgo(context), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textMuted, fontSize: 12))),
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(distanceLabel!, style: context.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                          const SizedBox(width: 2),
                          Icon(Icons.near_me_rounded, size: 11, color: AppColors.primary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 30, height: 30, decoration: BoxDecoration(color: context.palette.surfaceAlt, shape: BoxShape.circle), child: Icon(Icons.chevron_right_rounded, size: 18, color: context.palette.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(BuildContext context) {
    final timestamp = caseData.createdAt ?? caseData.missingSince;
    final diff = DateTime.now().toUtc().difference(timestamp.toUtc());
    final mins = diff.inMinutes;
    if (mins < 1) return context.tr('timeAgo.justNow');
    if (mins < 60) return context.tr('timeAgo.minutes', namedArgs: {'count': '$mins'});
    final hrs = diff.inHours;
    if (hrs < 24) return context.tr('timeAgo.hours', namedArgs: {'count': '$hrs'});
    final days = diff.inDays;
    if (days < 7) return context.tr('timeAgo.days', namedArgs: {'count': '$days'});
    final weeks = (days / 7).floor();
    return context.tr('timeAgo.weeks', namedArgs: {'count': '$weeks'});
  }
}
