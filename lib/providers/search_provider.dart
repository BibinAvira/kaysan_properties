import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../repositories/projects_repository.dart';
import 'di_providers.dart';
import 'projects_provider.dart';

/// Search State: holds the current [ProjectFilter] the user has configured
/// via the search bar / filter sheet.
class ProjectFilterController extends Notifier<ProjectFilter> {
  @override
  ProjectFilter build() => const ProjectFilter();

  void setQuery(String query) => state = state.copyWith(query: query);
  void setDistrict(int? districtId) =>
      state = state.copyWith(districtId: districtId, clearDistrict: districtId == null);
  void setDeveloper(int? developerId) =>
      state = state.copyWith(developerId: developerId, clearDeveloper: developerId == null);
  void setPriceRange(double? min, double? max) =>
      state = state.copyWith(minPrice: min, maxPrice: max, clearPrice: min == null && max == null);
  void setSort(ProjectSort sort) => state = state.copyWith(sort: sort);

  void clearAll() => state = ProjectFilter(query: state.query);
  void reset() => state = const ProjectFilter();
}

final NotifierProvider<ProjectFilterController, ProjectFilter> projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(ProjectFilterController.new);

/// Derived provider: the loaded project pages run through the active
/// filter/sort. Only covers pages fetched so far (see [ProjectFilter]'s
/// doc comment) — the Listings screen keeps loading more pages as the
/// user scrolls, and this recomputes automatically as they arrive.
final Provider<AsyncValue<List<ProjectModel>>> filteredProjectsProvider =
    Provider<AsyncValue<List<ProjectModel>>>((Ref ref) {
  final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
  final ProjectFilter filter = ref.watch(projectFilterProvider);
  final ProjectsRepository repo = ref.watch(projectsRepositoryProvider);

  return pageState.whenData((ProjectsPageState s) => repo.applyFilter(s.items, filter));
});
