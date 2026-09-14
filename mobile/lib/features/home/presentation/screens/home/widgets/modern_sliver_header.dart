import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../../core/storage/stores.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/context_extensions.dart';
import 'glass_pill.dart';
import 'modern_notification_bell.dart';

class ModernSliverHeader extends StatelessWidget {
  const ModernSliverHeader({super.key, required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greetingKey = hour < 12
        ? 'home.greetingMorning'
        : hour < 18
            ? 'home.greetingAfternoon'
            : 'home.greetingEvening';
    final authStore = getIt<AuthStore>();
    final rawName = authStore.userName?.trim();
    final userName = (rawName != null && rawName.isNotEmpty) ? rawName : 'مصطفى';
    final initialLetter = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'م';

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: context.palette.background.withValues(alpha: 0.85),
      surfaceTintColor: Colors.transparent,
      expandedHeight: 88,
      collapsedHeight: 72,
      flexibleSpace: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.background.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(color: context.palette.border.withValues(alpha: 0.6)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.xl, 10, AppDimens.xl, 10),
              child: Row(
                children: [
                  // Avatar with gradient ring + online dot
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                           gradient: AppColors.brandGradient,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: context.palette.surface,
                          child: Text(
                            initialLetter,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.palette.surface, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.35),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.tr(greetingKey),
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: context.palette.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$userName 👋',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Location pill — glass
                  const GlassPill(
                    icon: Icons.location_on_rounded,
                    label: 'القاهرة',
                    iconColor: AppColors.secondary,
                  ),
                  const SizedBox(width: AppDimens.sm),
                  ModernNotificationBell(unreadCount: unreadCount),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
