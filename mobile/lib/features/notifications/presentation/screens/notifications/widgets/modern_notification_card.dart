import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/utils/date_formats.dart';
import '../../../../../shared/domain/app_enums.dart';
import '../../../../domain/app_notification.dart';

class VeryModernCard extends StatelessWidget {
  const VeryModernCard({super.key, required this.notification, required this.index});
  final AppNotification notification;
  final int index;

  (Color, IconData, Gradient) get _visual => switch (notification.type) {
        AppNotificationType.emergency => (AppColors.emergency, Icons.bolt_rounded, AppColors.emergencyGradient),
        AppNotificationType.caseUpdate => (AppColors.info, Icons.sync_rounded, AppColors.coolGradient),
        AppNotificationType.possibleMatch => (AppColors.secondary, Icons.handshake_rounded, AppColors.warmGradient),
        AppNotificationType.success => (AppColors.success, Icons.favorite_rounded, AppColors.successGradient),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon, gradient) = _visual;
    final bool unread = !notification.read;
    final bool isEmergency = notification.isEmergency;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: notification.caseId == null ? null : () => context.router.push(ChildDetailsRoute(caseId: notification.caseId!)),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: unread ? color.withValues(alpha: 0.22) : context.palette.border.withValues(alpha: 0.9)),
            boxShadow: unread
                ? [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // unread accent
                  AnimatedContainer(duration: 220.ms, width: unread ? 4 : 0, color: unread ? color : Colors.transparent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // icon
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: unread ? gradient : null,
                              color: unread ? null : color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: unread ? [BoxShadow(color: color.withValues(alpha: 0.24), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Icon(icon, size: 22, color: unread ? Colors.white : color),
                          ),
                          const SizedBox(width: 12),
                          // text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(context.tr(notification.titleKey, namedArgs: notification.namedArgs), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: unread ? FontWeight.w900 : FontWeight.w700, fontSize: 13.5, height: 1.2))),
                                    const SizedBox(width: 8),
                                    Text(DateFormats.compact(notification.createdAt), style: context.textTheme.labelSmall?.copyWith(color: context.palette.textMuted, fontSize: 11)),
                                    if (unread) ...[
                                      const SizedBox(width: 8),
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.emergency, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.2)))
                                          .animate(onPlay: (c) => c.repeat(reverse: true))
                                          .scale(begin: const Offset(1, 1), end: const Offset(1.22, 1.22), duration: 900.ms),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(context.tr(notification.bodyKey, namedArgs: notification.namedArgs), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 12.5, height: 1.45)),
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    if (isEmergency)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.emergency.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(100)),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.warning_amber_rounded, size: 11, color: AppColors.emergency), const SizedBox(width: 3), Text(context.tr('notifications.urgent'), style: context.textTheme.labelSmall?.copyWith(color: AppColors.emergency, fontWeight: FontWeight.w800, fontSize: 10))]),
                                      ),
                                    if (isEmergency) const SizedBox(width: 8),
                                    if (notification.caseId != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(100)),
                                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.visibility_outlined, size: 13, color: AppColors.primary), const SizedBox(width: 4), Text(context.tr('notifications.view'), style: context.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 11))]),
                                      ),
                                    const Spacer(),
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(color: context.palette.surfaceAlt, shape: BoxShape.circle),
                                      child: Icon(Icons.chevron_right_rounded, size: 16, color: context.palette.textMuted),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
