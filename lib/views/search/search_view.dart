import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/favorites_provider.dart';
import '../../repositories/projects_repository.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Standalone Property Search screen, reached from the Home search bar /
/// filter icon. Results show inline on this same screen as the query
/// changes — this used to redirect to the Listings screen on submit,
/// which meant the "search" screen itself never showed a single result.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late final TextEditingController _controller =
      TextEditingController(text: ref.read(projectFilterProvider).query);

  static const List<String> _suggestions = <String>[
    'Dubai Marina',
    'Downtown Dubai',
    'Business Bay',
    'Emaar',
    'Sobha',
    'Villas',
    'Ready to move',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    ref.read(projectFilterProvider.notifier).setQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(projectFilterProvider.select((ProjectFilter f) => f.query));
    final AsyncValue<List<ProjectModel>> results = ref.watch(filteredProjectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Find your dream off-plan property',
          ),
          onChanged: (String v) => ref.read(projectFilterProvider.notifier).setQuery(v),
        ),
      ),
      body: query.trim().isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text('Popular Searches',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map((String s) =>
                          ActionChip(label: Text(s), onPressed: () => _setQuery(s)))
                      .toList(),
                ),
              ],
            )
          : results.when(
              loading: () => const PropertyGridShimmer(),
              error: (Object e, StackTrace st) => const EmptyStateView(
                icon: Icons.error_outline,
                title: 'Something went wrong',
                message: 'Could not search right now. Please try again.',
              ),
              data: (List<ProjectModel> list) {
                if (list.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No properties found',
                    message: 'Try a different project, area, or developer name.',
                  );
                }
                final Set<int> favIds =
                    favorites.maybeWhen(data: (Set<int> s) => s, orElse: () => <int>{});
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ProjectModel project = list[index];
                    return PropertyCard(
                      project: project,
                      isFavorite: favIds.contains(project.id),
                      onFavoriteTap: () async {
                        if (await requireAuth(context, ref)) {
                          ref.read(favoritesProvider.notifier).toggle(project.id);
                        }
                      },
                      onTap: () =>
                          context.push(RouteNames.propertyDetailsPath(project.id)),
                    );
                  },
                );
              },
            ),
    );
  }
}
