import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../../../core/router/app_router.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../auth/domain/user.dart';
import 'hero_meta.dart';
import 'pill_mini.dart';

class HeroProfileCard extends StatelessWidget {
  const HeroProfileCard({
    super.key,
    required this.user,
    this.reportsCount = 0,
    this.helpedCount = 0,
  });
  final User? user;
  final int reportsCount;
  final int helpedCount;

  @override
  Widget build(BuildContext context) {
    final isGuest = user == null || user!.id == 'guest';
    final name = !isGuest && user!.fullName.isNotEmpty
        ? user!.fullName
        : context.tr('auth.guest');
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : (user?.phone?.isNotEmpty == true ? user!.phone! : '');
    final location = user?.city?.isNotEmpty == true
        ? user!.city!
        : context.tr('profile.heroLocation');
    final initial = name.isEmpty ? '؟' : name.trim()[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF009688)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withValues(alpha: 0.18), blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(top: -30, right: -30, child: Container(width: 140, height: 140, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), shape: BoxShape.circle))),
            Positioned(bottom: -40, left: -24, child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16)]),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Text(initial, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
                              child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.1)),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.78), fontSize: 12)),
                            ],
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                PillMini(icon: Icons.verified_rounded, label: context.tr('profile.heroVerified')),
                                const SizedBox(width: 6),
                                PillMini(icon: Icons.location_on_rounded, label: location),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // edit
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => context.router.push(const EditProfileRoute()),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // quick meta row — only Reports & Helped (rating removed)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
                    child: Row(
                      children: [
                        HeroMeta(label: context.tr('profile.heroReports'), value: '$reportsCount', icon: Icons.description_outlined),
                        Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.12)),
                        HeroMeta(label: context.tr('profile.heroHelped'), value: '$helpedCount', icon: Icons.favorite_rounded),
                      ],
                    ),
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
