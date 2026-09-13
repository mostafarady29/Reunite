import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../../domain/child_case.dart';
import '../../../forms/share_case.dart';
import 'glass_btn.dart';

/// Photo backdrop (380px) with gradient, top bar and bottom meta chips.
/// Extracted from `details_hero.dart`. No logic changes.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({super.key, required this.caseData});
  final ChildCase caseData;

  @override
  Widget build(BuildContext context) {
    final isResolved = caseData.isResolved;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 380,
      child: Container(
        decoration: BoxDecoration(
          gradient: isResolved
              ? AppColors.successGradient
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E3A5F),
                    Color(0xFF0B3D2E),
                  ],
                ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.38,
                child: ChildPhoto(
                  seed: caseData.locality,
                  imagePath: caseData.photoPath,
                  size: 380,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    GlassBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.router.maybePop(),
                    ),
                    const Spacer(),
                    GlassBtn(
                      icon: Icons.share_rounded,
                      onTap: () => shareCase(context, caseData),
                    ),
                    const SizedBox(width: 8),
                    GlassBtn(
                      icon: Icons.bookmark_border_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 60,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18))),
                    child: Text(
                        '#${caseData.id.length >= 8 ? caseData.id.substring(0, 8) : caseData.id}',
                        style: context.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(100)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(caseData.verified ? Icons.verified_rounded : Icons.access_time_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(caseData.verified ? context.tr('status.verified') : context.tr('status.${caseData.status.name}'),
                          style: context.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ]),
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
