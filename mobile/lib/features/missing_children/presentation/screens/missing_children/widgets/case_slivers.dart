import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/utils/distance_format.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../../reports/domain/child_case.dart';
import '../../../../../shared/domain/app_enums.dart';
import '../../../missing_cubit.dart';

class ListSliver extends StatelessWidget {
  const ListSliver({super.key, required this.cases, required this.cubit});
  final List<ChildCase> cases;
  final MissingCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: cases.length,
      itemBuilder: (context, i) {
        final c = cases[i];
        final dist = cubit.distanceTo(c);
        return Padding(
          padding: EdgeInsets.only(bottom: i == cases.length - 1 ? 0 : 14),
          child: ChildCaseCard(
            caseData: c,
            distanceLabel: dist != null ? DistanceFormat.format(dist) : null,
            onTap: () => context.router.push(ChildDetailsRoute(caseId: c.id)),
          ).animate().fadeIn(delay: (60 + i * 40).ms, duration: 380.ms).slideY(begin: 0.08).scale(begin: const Offset(0.99, 0.99)),
        );
      },
    );
  }
}

class GridSliver extends StatelessWidget {
  const GridSliver({super.key, required this.cases, required this.cubit});
  final List<ChildCase> cases;
  final MissingCubit cubit;

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
      itemCount: cases.length,
      itemBuilder: (context, i) {
        final c = cases[i];
        final dist = cubit.distanceTo(c);
        return GridCard(caseData: c, distanceLabel: dist != null ? DistanceFormat.format(dist) : null).animate().fadeIn(delay: (40 + i * 30).ms).scale(begin: const Offset(0.96, 0.96));
      },
    );
  }
}

class GridCard extends StatelessWidget {
  const GridCard({super.key, required this.caseData, this.distanceLabel});
  final ChildCase caseData;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.router.push(ChildDetailsRoute(caseId: caseData.id)),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.border.withValues(alpha: 0.9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image — clean, no urgent dot
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(height: 112, width: double.infinity, child: ChildPhoto(seed: caseData.locality, imagePath: caseData.photoPath, size: 112, radius: 0, borderRadius: const BorderRadius.vertical(top: Radius.circular(18)))),
                  ),
                  if (distanceLabel != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.56), borderRadius: BorderRadius.circular(100)),
                        child: Text(distanceLabel!, style: context.textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              // info
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caseData.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${caseData.age} ${context.tr('missing.yearsOld')} • ${context.tr(caseData.gender.key)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 11)),
                    const SizedBox(height: 6),
                    Row(children: [Icon(Icons.location_on_rounded, size: 11, color: context.palette.textMuted), const SizedBox(width: 3), Expanded(child: Text(caseData.area, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textMuted, fontSize: 11)))]),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(child: Text(_timeAgo(context), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelSmall?.copyWith(color: context.palette.textMuted, fontSize: 10))),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
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

  String _timeAgo(BuildContext context) {
    final mins = DateTime.now().difference(caseData.missingSince).inMinutes;
    if (mins < 1) return context.tr('timeAgo.justNow');
    if (mins < 60) return context.tr('timeAgo.minutes', namedArgs: {'count': '$mins'});
    final hrs = (mins / 60).floor();
    if (hrs < 24) return context.tr('timeAgo.hours', namedArgs: {'count': '$hrs'});
    final days = (hrs / 24).floor();
    return context.tr('timeAgo.days', namedArgs: {'count': '$days'});
  }
}
