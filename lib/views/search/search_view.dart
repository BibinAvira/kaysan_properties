import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../providers/search_provider.dart';

/// Standalone Property Search screen (separate from the Listings filter
/// bar) — a focused search entry point with quick-pick suggestions, useful
/// when reached from the Home app bar search icon.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _controller = TextEditingController();

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

  void _search(String query) {
    ref.read(projectFilterProvider.notifier).setQuery(query);
    context.go(RouteNames.listings);
  }

  @override
  Widget build(BuildContext context) {
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
          onSubmitted: _search,
        ),
      ),
      body: ListView(
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
                    ActionChip(label: Text(s), onPressed: () => _search(s)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
