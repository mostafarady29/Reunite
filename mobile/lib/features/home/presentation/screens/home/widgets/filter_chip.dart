import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';

class HomeFilterChip extends StatelessWidget {
  const HomeFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? context.colorScheme.primary : context.palette.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: selected ? context.colorScheme.primary : context.palette.border),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : context.palette.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : context.palette.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
