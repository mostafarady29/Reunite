import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';

class NotifCard extends StatelessWidget {
  const NotifCard({super.key, required this.pushEnabled, required this.nearby, required this.updates, required this.matches, required this.onPush, required this.onNearby, required this.onUpdates, required this.onMatches});
  final bool pushEnabled;
  final bool nearby;
  final bool updates;
  final bool matches;
  final ValueChanged<bool> onPush;
  final ValueChanged<bool> onNearby;
  final ValueChanged<bool> onUpdates;
  final ValueChanged<bool> onMatches;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: context.palette.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          ToggleTile(icon: Icons.notifications_active_rounded, color: AppColors.primary, title: context.tr('profile.pushEnabled'), subtitle: 'Master switch for all alerts', value: pushEnabled, onChanged: onPush),
          const SettingsDivider(),
          ToggleTile(icon: Icons.near_me_rounded, color: AppColors.secondary, title: context.tr('profile.alertsNearby'), subtitle: 'Missing near your radius', value: nearby, onChanged: onNearby),
          const SettingsDivider(),
          ToggleTile(icon: Icons.sync_rounded, color: AppColors.info, title: context.tr('profile.caseUpdates'), subtitle: 'Status changes on your reports', value: updates, onChanged: onUpdates),
          const SettingsDivider(),
          ToggleTile(icon: Icons.handshake_rounded, color: AppColors.accent, title: context.tr('profile.matches'), subtitle: 'Possible matches found', value: matches, onChanged: onMatches),
        ],
      ),
    );
  }
}

class ToggleTile extends StatelessWidget {
  const ToggleTile({super.key, required this.icon, required this.color, required this.title, required this.subtitle, required this.value, required this.onChanged});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)), Text(subtitle, style: context.textTheme.bodySmall?.copyWith(color: context.palette.textSecondary, fontSize: 11.5))])),
          const SizedBox(width: 10),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});
  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, color: context.palette.border.withValues(alpha: 0.7), indent: 66);
}
