import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../data/repositories/child_case_repository.dart';

/// Single possible-match card, extracted from `matches_section.dart`.
class MatchModernCard extends StatelessWidget {
  const MatchModernCard({super.key, required this.match});
  final PossibleMatch match;
  @override
  Widget build(BuildContext context) {
    final f = match.foundCase;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 48,
              height: 48,
              child: ChildPhoto(
                seed: f.locality,
                imagePath: f.photoPath,
                size: 48,
                radius: 0,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${match.matchPercent.round()}% match',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: match.matchPercent / 100,
                          minHeight: 5,
                          backgroundColor: context.palette.surfaceAlt,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${f.age} ${context.tr('missing.yearsOld')} • ${f.area}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.palette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, color: context.palette.textMuted),
        ],
      ),
    );
  }
}
