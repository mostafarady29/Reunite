import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_dimens.dart';
import '../../../home_cubit.dart';
import 'error_card.dart';
import 'home_content.dart';
import 'home_skeleton.dart';

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.state, required this.cubit});
  final HomeState state;
  final HomeCubit cubit;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      HomeLoading() => const HomeSkeleton(),
      HomeError() => Padding(
          padding: const EdgeInsets.all(AppDimens.lg),
          child: ErrorCard(onRetry: cubit.load),
        ),
      HomeLoaded(:final emergency, :final nearby, :final stats, :final userLocation) =>
        HomeContent(
          emergency: emergency,
          nearby: nearby,
          stats: stats,
          userLocation: userLocation,
        ),
      _ => const SizedBox(),
    };
  }
}
