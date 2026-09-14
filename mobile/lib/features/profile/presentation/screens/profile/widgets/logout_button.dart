import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../profile_cubit.dart';

class ModernLogout extends StatefulWidget {
  const ModernLogout({super.key});

  @override
  State<ModernLogout> createState() => _ModernLogoutState();
}

class _ModernLogoutState extends State<ModernLogout> {
  bool _loading = false;

  Future<void> _handleLogout() async {
    final ok = await showAppConfirmDialog(
      context,
      title: context.tr('profile.logout'),
      message: context.tr('profile.logout'),
      destructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await context.read<ProfileCubit>().logout();
    } catch (_) {
      // Local session was already cleared inside the cubit.
    }
    if (!mounted) return;
    // Use the root router so it works even if ProfileCubit's BLoC scope closes.
    getIt<AppRouter>().replaceAll([const OnboardingRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _handleLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.emergency.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.emergency.withValues(alpha: 0.16)),
          ),
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.emergency,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 18, color: AppColors.emergency),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('profile.logout'),
                      style: context.textTheme.titleSmall?.copyWith(
                        color: AppColors.emergency,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
