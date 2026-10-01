import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/content_providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/developer_tile.dart';
import '../../widgets/loading_shimmer.dart';

/// Full developer directory ("See All" from Home's "Developers We Work
/// With"): every developer from [developersProvider] — the client's
/// featured ones first — with a name search. The grid is lazy, so only
/// the cards on screen are built and have their logos loaded, even though
/// the directory runs to ~800 developers.
class DevelopersView extends ConsumerStatefulWidget {
  const DevelopersView({super.key});

  @override
  ConsumerState<DevelopersView> createState() => _DevelopersViewState();
}

class _DevelopersViewState extends ConsumerState<DevelopersView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DeveloperModel>> developers =
        ref.watch(developersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Developers')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search developers',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (String v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: developers.when(
              loading: () => const PropertyGridShimmer(),
              error: (Object e, StackTrace st) => EmptyStateView(
                icon: Icons.error_outline,
                title: 'Could not load developers',
                message: 'Please check your connection and try again.',
                actionLabel: 'Retry',
                onActionTap: () => ref.invalidate(developersProvider),
              ),
              data: (List<DeveloperModel> list) {
                final String q = _query.trim().toLowerCase();
                final List<DeveloperModel> matches = q.isEmpty
                    ? list
                    : list
                        .where((DeveloperModel d) =>
                            d.name.toLowerCase().contains(q))
                        .toList();
                if (matches.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No developers found',
                    message: 'Try a different name.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DeveloperModel developer = matches[index];
                    return DeveloperTile(
                      developer: developer,
                      onTap: () => context.push(
                          RouteNames.developerDetailsPath(developer.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
