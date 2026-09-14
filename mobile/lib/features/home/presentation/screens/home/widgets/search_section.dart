import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/context_extensions.dart';
import 'filter_chip.dart';

class SearchSection extends StatefulWidget {
  const SearchSection({super.key, required this.onSearchTap});
  final VoidCallback onSearchTap;

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  int _selected = 0;

  void _onChipTapped(int index) {
    setState(() => _selected = index);
    if (index == 0) {
      try {
        AutoTabsRouter.of(context).setActiveIndex(1);
      } catch (_) {
        context.router.push(const MissingChildrenRoute());
      }
    } else if (index == 1) {
      try {
        AutoTabsRouter.of(context).setActiveIndex(2);
      } catch (_) {
        context.router.push(const MapRoute());
      }
    } else if (index == 2) {
      context.router.push(const SearchRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppDimens.xl, 0, AppDimens.xl, AppDimens.xl),
      child: Column(
        children: [
          // Premium search bar with shadow + action
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.palette.border),
              boxShadow: [
                BoxShadow(color: context.palette.cardShadow, blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSearchTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr('home.searchHint'),
                          style: context.textTheme.bodyMedium?.copyWith(color: context.palette.textMuted),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 16, color: context.palette.textSecondary),
                            const SizedBox(width: 4),
                            Text(context.tr('missing.filters'), style: context.textTheme.labelSmall?.copyWith(color: context.palette.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                HomeFilterChip(
                  label: context.tr('home.filterAllCases'),
                  icon: Icons.apps_rounded,
                  selected: _selected == 0,
                  onTap: () => _onChipTapped(0),
                ),
                const SizedBox(width: 8),
                HomeFilterChip(
                  label: context.tr('home.filterNearby'),
                  icon: Icons.near_me_rounded,
                  selected: _selected == 1,
                  onTap: () => _onChipTapped(1),
                ),
                const SizedBox(width: 8),
                HomeFilterChip(
                  label: context.tr('home.filterToday'),
                  icon: Icons.today_rounded,
                  selected: _selected == 2,
                  onTap: () => _onChipTapped(2),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 120.ms, duration: 400.ms).slideY(begin: 0.06);
  }
}
