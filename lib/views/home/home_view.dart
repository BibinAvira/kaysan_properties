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
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(blogsProvider);
            ref.invalidate(testimonialsProvider);
            await ref.read(projectsProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: const <Widget>[
              HomeGreetingHeader(),
              HomeHeadline(),
              HomeSearchBar(),
              SizedBox(height: 12),
              SignUpNudgeBanner(),
              SizedBox(height: 4),
              HomeCategoryChips(),
              SizedBox(height: 8),
              TopPropertySection(),
              SizedBox(height: 8),
              LatestProjectsSection(title: 'Latest Off-Plan Projects'),
              SizedBox(height: 8),
              //  StatsSection(),
              DevelopersSection(),
              AreasSection(),
              WhyChooseSection(),
              TestimonialsSection(),
              BlogsSection(),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
