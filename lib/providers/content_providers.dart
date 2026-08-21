import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../models/supporting_models.dart';
import 'di_providers.dart';
import 'projects_provider.dart';

/// Areas, **derived** from whatever property pages have loaded so far by
/// grouping on `district` — there's no standalone areas endpoint. This
/// recomputes automatically as more pages load via [projectsProvider].
final Provider<AsyncValue<List<AreaModel>>> areasProvider =
    Provider<AsyncValue<List<AreaModel>>>((Ref ref) {
  final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
  return pageState.whenData((ProjectsPageState s) => AreaModel.fromProjects(s.items));
});

/// Developers, **derived** the same way — distinct developers across the
/// loaded projects, most-listed first.
final Provider<AsyncValue<List<DeveloperModel>>> developersProvider =
    Provider<AsyncValue<List<DeveloperModel>>>((Ref ref) {
  final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
  return pageState.whenData((ProjectsPageState s) {
    final Map<int, List<ProjectModel>> byDeveloper = <int, List<ProjectModel>>{};
    for (final ProjectModel p in s.items) {
      byDeveloper.putIfAbsent(p.developer.id, () => <ProjectModel>[]).add(p);
    }
    final List<MapEntry<int, List<ProjectModel>>> entries = byDeveloper.entries.toList()
      ..sort((MapEntry<int, List<ProjectModel>> a, MapEntry<int, List<ProjectModel>> b) =>
          b.value.length.compareTo(a.value.length));
    return entries.map((MapEntry<int, List<ProjectModel>> e) => e.value.first.developer).toList();
  });
});

final FutureProvider<List<BlogModel>> blogsProvider = FutureProvider<List<BlogModel>>((Ref ref) {
  return ref.watch(blogsRepositoryProvider).getBlogs();
});

final FutureProvider<List<TestimonialModel>> testimonialsProvider =
    FutureProvider<List<TestimonialModel>>((Ref ref) {
  return ref.watch(blogsRepositoryProvider).getTestimonials();
});
