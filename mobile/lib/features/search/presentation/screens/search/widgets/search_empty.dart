import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/di/app_di.dart';
import '../../../../../../core/locations/location_models.dart';
import '../../../../../../core/locations/locations_repository.dart';
import '../../../../../../core/theme/app_dimens.dart';
import '../../../../../../core/utils/context_extensions.dart';
import '../../../../../../core/widgets/widgets.dart';
import '../../../search_cubit.dart';

class SearchEmptyView extends StatelessWidget {
  const SearchEmptyView({super.key, required this.recent});

  final List<String> recent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recent.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(context.tr('search.recent'),
                      style: context.textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<SearchCubit>().clearRecent(),
                  child: Text(context.tr('search.clearRecent')),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            Wrap(
              spacing: AppDimens.sm,
              runSpacing: AppDimens.sm,
              children: recent.map((q) {
                return ActionChip(
                  label: Text(q),
                  onPressed: () {
                    context.read<SearchCubit>().search(q);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppDimens.xxl),
          ],
          FutureBuilder<List<Governorate>>(
            future: getIt<LocationsRepository>().getGovernorates(),
            builder: (context, snapshot) {
              final areas = (snapshot.data ?? const <Governorate>[])
                  .map((g) => g.name)
                  .where((n) => n.isNotEmpty)
                  .take(6)
                  .toList();
              if (areas.isEmpty) return const SizedBox();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('search.popularAreas'),
                      style: context.textTheme.titleMedium),
                  const SizedBox(height: AppDimens.md),
                  ...areas.map((area) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, size: 20),
                      title: Text(area),
                      onTap: () => context.read<SearchCubit>().search(area),
                    );
                  }),
                ],
              );
            },
          ),
          const SizedBox(height: AppDimens.xl),
          EmptyState(
            title: context.tr('search.empty'),
            subtitle: context.tr('search.emptySub'),
            icon: Icons.search_off_rounded,
          ),
        ],
      ),
    );
  }
}
