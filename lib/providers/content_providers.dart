import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../models/supporting_models.dart';
import '../repositories/projects_repository.dart' show featuredDeveloperIds;
import 'di_providers.dart';
import 'projects_provider.dart';
import '../services/projects_service.dart';

/// Areas, **derived** from whatever property pages have loaded so far by
/// grouping on `district` — there's no standalone areas endpoint. This
/// recomputes automatically as more pages load via [projectsProvider].
final Provider<AsyncValue<List<AreaModel>>> areasProvider =
    Provider<AsyncValue<List<AreaModel>>>((Ref ref) {
  final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
  return pageState.whenData((ProjectsPageState s) => AreaModel.fromProjects(s.items));
});

/// The full developer directory, fetched once from Reelly's `/developers`
/// endpoint (~800 entries) rather than derived from whichever projects
/// happen to be loaded — unlike [areasProvider], a real directory endpoint
/// exists for this, so every developer is available immediately instead of
/// only the ones seen so far.
///
/// [featuredDeveloperIds] (the client's chosen developers) are listed first,
/// in that order, followed by the rest of the directory as the API returns it.
final FutureProvider<List<DeveloperModel>> developersProvider =
    FutureProvider<List<DeveloperModel>>((Ref ref) async {
  final List<DeveloperModel> all =
      await ref.watch(projectsRepositoryProvider).getAllDevelopers();
  final Map<int, DeveloperModel> byId = <int, DeveloperModel>{
    for (final DeveloperModel d in all) d.id: d,
  };
  final List<DeveloperModel> featured = <DeveloperModel>[
    for (final int id in featuredDeveloperIds)
      if (byId[id] != null) byId[id]!,
  ];
  return <DeveloperModel>[
    ...featured,
    ...all.where((DeveloperModel d) => !featuredDeveloperIds.contains(d.id)),
  ];
});

final FutureProvider<List<BlogModel>> blogsProvider = FutureProvider<List<BlogModel>>((Ref ref) {
  return ref.watch(blogsRepositoryProvider).getBlogs();
});

final FutureProvider<List<TestimonialModel>> testimonialsProvider =
    FutureProvider<List<TestimonialModel>>((Ref ref) {
  return ref.watch(blogsRepositoryProvider).getTestimonials();
});

/// Reelly's full area list (357), for the filter sheet's Area picker.
final FutureProvider<List<AreaRef>> allAreasProvider =
    FutureProvider<List<AreaRef>>((Ref ref) {
  return ref.watch(projectsRepositoryProvider).getAllAreas();
});

/// An area shortcut on Home ("Explore by Area" / "Popular Areas"): a short
/// display [label] for a Reelly `/districts` entry, filtered server-side
/// by [districtId] when tapped.
class HomeArea {
  const HomeArea(this.label, this.districtId, this.districtName);
  final String label;
  final int districtId;

  /// Reelly's own spelling, matched against [ProjectModel.district] when
  /// results are also narrowed on-device (e.g. combined with a search).
  final String districtName;
}

/// The client's highlighted areas, in display order.
const List<HomeArea> homeAreas = <HomeArea>[
  HomeArea('Dubai Marina', 217, 'Dubai Marina'),
  HomeArea('Downtown Dubai', 201, 'Downtown Dubai'),
  HomeArea('Palm Jumeirah', 308, 'Palm Jumeirah'),
  HomeArea('JVC', 269, 'JVC (Jumeirah Village Circle)'),
  HomeArea('Business Bay', 187, 'Business Bay'),
];

/// Cover photo URL for a [HomeArea] (empty if none of its projects has
/// one), cached for the session.
final FutureProviderFamily<String, int> areaCoverProvider =
    FutureProvider.family<String, int>((Ref ref, int districtId) {
  return ref.watch(projectsRepositoryProvider).getAreaCover(districtId);
});
