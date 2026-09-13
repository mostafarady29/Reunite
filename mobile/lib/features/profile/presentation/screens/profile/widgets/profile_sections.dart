import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 18, color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1)), Text(subtitle, style: context.textTheme.labelSmall?.copyWith(color: context.palette.textSecondary, fontSize: 11))])),
      ],
    );
  }
}

class ReportsBento extends StatelessWidget {
  const ReportsBento({
    super.key,
    this.missingCount = 0,
    this.foundCount = 0,
  });
  final int missingCount;
  final int foundCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_search_rounded, context.tr('profile.reportsMissing'), '$missingCount', AppColors.primary, AppColors.primary.withValues(alpha: 0.10), context.tr('profile.reportsMissingSub')),
      (Icons.check_circle_rounded, context.tr('profile.reportsFound'), '$foundCount', AppColors.success, AppColors.successSoft, context.tr('profile.reportsFoundSub')),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
      itemBuilder: (context, i) {
        final (icon, label, count, color, bg, sub) = items[i];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.router.push(const MyReportsRoute()),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: context.palette.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 48, height: 48, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)), child: Icon(icon, size: 24, color: color)),
                      const Spacer(),
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: context.palette.surfaceAlt, shape: BoxShape.circle), child: Icon(Icons.arrow_outward_rounded, size: 14, color: context.palette.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(count, style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, height: 1, fontSize: 26)),
                  const SizedBox(height: 2),
                  Text(label, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
