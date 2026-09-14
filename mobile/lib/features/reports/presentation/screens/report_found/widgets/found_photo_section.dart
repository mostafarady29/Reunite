import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import 'section_card.dart';

/// Optional photo section, extracted from `found_view.dart`.
class FoundPhotoSection extends StatelessWidget {
  const FoundPhotoSection({
    super.key,
    required this.photoSeed,
    required this.onChanged,
    required this.onClear,
  });
  final String? photoSeed;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return FoundSectionCard(
      icon: Icons.camera_alt_rounded,
      color: AppColors.primary,
      title: context.tr('report.foundPhotoOptional'),
      subtitle: context.tr('report.photoHint'),
      child: Column(
        children: [
          GestureDetector(
            onTap: onChanged,
            child: Container(
              width: double.infinity,
              height: 148,
              decoration: BoxDecoration(
                  color: context.palette.surfaceAlt.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: photoSeed == null
                          ? context.palette.border
                          : AppColors.success.withValues(alpha: 0.35))),
              child: photoSeed == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.10),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.add_a_photo_rounded,
                                  size: 22, color: AppColors.success)),
                          const SizedBox(height: 8),
                          Text(context.tr('report.tapToAddPhoto'),
                              style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(context.tr('report.photoHint'),
                              style: context.textTheme.bodySmall?.copyWith(
                                  color: context.palette.textSecondary,
                                  fontSize: 11)),
                        ])
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ChildPhoto(
                          seed: photoSeed,
                          imagePath: photoSeed,
                          size: 148,
                          borderRadius: BorderRadius.circular(16))),
            ),
          ),
          if (photoSeed != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text(context.tr('common.cancel')),
                      style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: onChanged,
                      icon: const Icon(Icons.refresh_rounded,
                          size: 16, color: Colors.white),
                      label: Text(context.tr('common.retry'),
                          style: context.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))))),
            ]),
          ],
        ],
      ),
    );
  }
}
