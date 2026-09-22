import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../domain/child_case.dart';
import '../../../../../shared/domain/app_enums.dart';
import 'details_utils.dart';
import 'details_divider.dart';
import 'info_block.dart';
import 'info_row.dart';

export 'details_divider.dart';
export 'info_block.dart';
export 'info_row.dart';

/// Grouped case facts card. Row/block/divider widgets live in their own
/// files so this file stays under the 150-line budget. No logic changes.
class InfoGroup extends StatelessWidget {
  const InfoGroup({super.key, required this.caseData});
  final ChildCase caseData;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InfoRowModern(
            icon: Icons.wc_rounded,
            color: AppColors.primary,
            label: context.tr('details.gender'),
            value: context.tr(caseData.gender.key),
          ),
          const DetailsDivider(),
          InfoRowModern(
            icon: Icons.event_rounded,
            color: AppColors.warning,
            label: context.tr('details.missingSince'),
            value: detailsDateTimeLabel(caseData.missingSince),
          ),
          const DetailsDivider(),
          InfoRowModern(
            icon: Icons.place_rounded,
            color: AppColors.info,
            label: context.tr('details.location'),
            value: caseData.lastKnownLocation,
          ),
          const DetailsDivider(),
          BlockModern(
            icon: Icons.checkroom_rounded,
            color: AppColors.secondary,
            label: context.tr('details.clothing'),
            value: caseData.clothing.isNotEmpty
                ? caseData.clothing
                : (context.locale.languageCode == 'ar' ? 'غير محدد' : 'Not specified'),
          ),
          if (caseData.distinguishingMarks != null) ...[
            const DetailsDivider(),
            BlockModern(
              icon: Icons.visibility_rounded,
              color: AppColors.accent,
              label: context.tr('details.distinguishingMarks'),
              value: caseData.distinguishingMarks!,
            ),
          ],
          const DetailsDivider(),
          BlockModern(
            icon: Icons.notes_rounded,
            color: const Color(0xFF6B7280),
            label: context.tr('details.description'),
            value: caseData.description,
          ),
        ],
      ),
    );
  }
}
