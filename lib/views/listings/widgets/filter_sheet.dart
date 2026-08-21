import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import '../../../models/project_model.dart';
import '../../../models/supporting_models.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/search_provider.dart';

/// Modal filter sheet for the Listings screen. Area/Developer options are
/// pulled live from [areasProvider]/[developersProvider] — i.e. whatever
/// has actually appeared in the loaded property pages — rather than a
/// hardcoded list, since the real API's districts/developers are numerous
/// and open-ended (over a thousand properties across many developers).
class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProjectFilter filter = ref.watch(projectFilterProvider);
    final ProjectFilterController controller =
        ref.read(projectFilterProvider.notifier);
    final List<AreaModel> areas =
        ref.watch(areasProvider).valueOrNull ?? <AreaModel>[];
    final List<DeveloperModel> developers =
        ref.watch(developersProvider).valueOrNull ?? <DeveloperModel>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Filters',
                    style: Theme.of(context).textTheme.headlineSmall),
                TextButton(
                    onPressed: controller.reset,
                    child: const Text('Clear all')),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Area', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Based on the ${areas.length} areas seen so far — scroll the list to load more.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: areas.map((AreaModel area) {
                      final bool isSelected =
                          filter.districtId == area.districtId;
                      return ChoiceChip(
                        label: Text('${area.name} (${area.projectCount})'),
                        selected: isSelected,
                        onSelected: (bool value) => controller
                            .setDistrict(value ? area.districtId : null),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Developer',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: developers.map((DeveloperModel dev) {
                      final bool isSelected = filter.developerId == dev.id;
                      return ChoiceChip(
                        label: Text(dev.name),
                        selected: isSelected,
                        onSelected: (bool value) =>
                            controller.setDeveloper(value ? dev.id : null),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjectSort.values.map((ProjectSort sort) {
                return ChoiceChip(
                  label: Text(_sortLabel(sort)),
                  selected: filter.sort == sort,
                  onSelected: (bool _) => controller.setSort(sort),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Show Results'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _sortLabel(ProjectSort sort) {
    switch (sort) {
      case ProjectSort.recommended:
        return 'Recommended';
      case ProjectSort.priceLowToHigh:
        return 'Price: Low to High';
      case ProjectSort.priceHighToLow:
        return 'Price: High to Low';
      case ProjectSort.handoverSoonest:
        return 'Handover: Soonest';
    }
  }
}
