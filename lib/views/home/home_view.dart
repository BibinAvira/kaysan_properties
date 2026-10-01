import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/content_providers.dart';
import '../../providers/projects_provider.dart';
import 'widgets/home_header.dart';
import 'widgets/home_sections.dart';
import 'widgets/signup_nudge_banner.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // No SafeArea on top: the hero photo runs up under the status bar,
      // and HomeHero pads its own content below it.
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(areaCoverProvider);
          await ref.read(projectsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: const <Widget>[
            HomeHero(),
            ExploreByAreaSection(),
            SizedBox(height: 12),
            HomeCategoryChips(),
            SizedBox(height: 4),
            TopPropertySection(),
            SizedBox(height: 8),
            PopularAreasSection(),
            SizedBox(height: 12),
            SignUpNudgeBanner(),
            DevelopersSection(),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
