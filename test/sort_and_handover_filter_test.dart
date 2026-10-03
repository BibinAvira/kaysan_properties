import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaysan_properties/models/project_model.dart';
import 'package:kaysan_properties/providers/search_provider.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import 'package:kaysan_properties/repositories/ranking_engine.dart';
import 'package:kaysan_properties/services/api_service.dart';
import 'package:kaysan_properties/services/projects_service.dart';

import 'support/project_factory.dart';

List<int> ids(Iterable<ProjectModel> list) => list.map((ProjectModel p) => p.id).toList();

void main() {
  // ---------------------------------------------------------------- sorts
  group('every sort', () {
    // A varied catalogue: every field each sort reads differs somewhere.
    final List<ProjectModel> catalog = <ProjectModel>[
      project(1, <String, dynamic>{'min_price': 900000.0, 'max_size': 800.0, 'max_bedrooms': 1, 'updated_at': '2026-09-01T00:00:00Z'}),
      project(2, <String, dynamic>{'developer': 'Emaar', 'min_price': 4200000.0, 'max_size': 5200.0, 'max_bedrooms': 5}),
      project(3, <String, dynamic>{'min_price': 0.0, 'max_size': 2100.0, 'max_bedrooms': null, 'min_bedrooms': null}),
      project(4, <String, dynamic>{'construction_status': 'completed', 'construction_start_date': '2019-01-01', 'completion_datetime': '2022-05-01T00:00:00Z', 'min_price': 2100000.0, 'max_size': 1300.0, 'max_bedrooms': 2, 'updated_at': '2026-10-02T00:00:00Z'}),
      project(5, <String, dynamic>{'construction_start_date': '2024-02-01', 'completion_datetime': '2026-12-31T00:00:00Z', 'min_price': 1250000.0, 'max_size': 1100.0, 'max_bedrooms': 3, 'updated_at': '2026-06-15T00:00:00Z'}),
      project(6, <String, dynamic>{'developer': 'Emaar', 'construction_start_date': null, 'completion_datetime': '2030-09-30T00:00:00Z', 'min_price': 3100000.0, 'max_size': 0.0, 'min_size': 1900.0, 'max_bedrooms': 4}),
    ];
    final RankingEngine engine = RankingEngine(catalog, now: testNow);
    final List<ProjectModel> best = engine.rank(catalog);

    for (final ProjectSort sort in ProjectSort.values) {
      test('${sort.name} keeps every project exactly once', () {
        final List<int> sorted = ids(engine.sort(best, sort));
        expect(sorted.length, best.length);
        expect(sorted.toSet(), ids(best).toSet());
      });
      test('${sort.name} has a label', () => expect(sort.label, isNotEmpty));
    }

    test('bestMatch: scores never go up down the list (bar the developer-run swap)', () {
      final List<ProjectModel> list = engine.sort(best, ProjectSort.bestMatch);
      for (int i = 1; i < list.length; i++) {
        final double prev = engine.scoreOf(list[i - 1]).total;
        final double cur = engine.scoreOf(list[i]).total;
        final bool runSwap = list[i - 1].developer.name != list[i].developer.name;
        expect(cur <= prev + 1e-9 || runSwap, isTrue, reason: '${list[i - 1].id} → ${list[i].id}');
      }
    });

    test('newest: latest launch first, estimated from handover when no start date', () {
      // 6 has no start date: handover 2030-09 − 34 months ≈ 2027-11 → clamped to now.
      expect(ids(engine.sort(best, ProjectSort.newest)).take(1), <int>[6]);
      expect(ids(engine.sort(best, ProjectSort.newest)).last, 4); // started 2019
    });

    test('recentlyUpdated: most recent updated_at first', () {
      final List<ProjectModel> list = engine.sort(best, ProjectSort.recentlyUpdated);
      expect(list.first.id, 4);
      expect(list.last.id, 5);
      for (int i = 1; i < list.length; i++) {
        expect(list[i].updatedAt!.isAfter(list[i - 1].updatedAt!), isFalse);
      }
    });

    test('price low → high: cheapest first, "On Request" last', () {
      expect(ids(engine.sort(best, ProjectSort.priceLowToHigh)), <int>[1, 5, 4, 6, 2, 3]);
    });

    test('price high → low: dearest first, "On Request" last', () {
      expect(ids(engine.sort(best, ProjectSort.priceHighToLow)), <int>[2, 6, 4, 5, 1, 3]);
    });

    test('largest area: biggest unit first, falls back to min size', () {
      expect(ids(engine.sort(best, ProjectSort.largestArea)), <int>[2, 3, 6, 4, 5, 1]);
    });

    test('bedrooms: most first, unknown last', () {
      expect(ids(engine.sort(best, ProjectSort.bedrooms)), <int>[2, 6, 5, 4, 1, 3]);
    });

    test('ready to move: ready buildings first', () {
      expect(engine.sort(best, ProjectSort.readyToMove).first.id, 4);
    });

    test('featured: featured developers first, Best Match within each group', () {
      final List<ProjectModel> list = engine.sort(best, ProjectSort.featured);
      expect(ids(list.take(2)).toSet(), <int>{2, 6});
      expect(list.skip(2).any(RankingEngine.isFeatured), isFalse);
    });

    test('impossible sizes and bedroom counts are ignored, not ranked first', () {
      final List<ProjectModel> list = <ProjectModel>[
        project(20, <String, dynamic>{'min_size': 563.0, 'max_size': 1710595.0}), // broken max
        project(21, <String, dynamic>{'max_size': 42909.0}),
        project(22, <String, dynamic>{'max_bedrooms': 20}), // broken
        project(23, <String, dynamic>{'max_bedrooms': 8}),
      ];
      final RankingEngine e = RankingEngine(list, now: testNow);
      final List<int> byArea = ids(e.sort(list, ProjectSort.largestArea));
      expect(byArea.first, 21);
      expect(byArea.indexOf(20), greaterThan(byArea.indexOf(22))); // falls back to its 563 sq.ft
      final List<int> byBeds = ids(e.sort(list, ProjectSort.bedrooms));
      expect(byBeds.first, 23);
      expect(byBeds.last, 22);
    });

    test('ties fall back to Best Match', () {
      final List<ProjectModel> twins = <ProjectModel>[
        project(10, <String, dynamic>{'min_price': 1000000.0, 'cover_image': <String, dynamic>{'url': 'x', 'metadata': <String, dynamic>{'width': 400}}}),
        project(11, <String, dynamic>{'min_price': 1000000.0}),
      ];
      final RankingEngine e = RankingEngine(twins, now: testNow);
      // Same price; 11 has the sharper photo, so it wins the tie.
      expect(ids(e.sort(twins, ProjectSort.priceLowToHigh)), <int>[11, 10]);
    });
  });

  group('handover sorts', () {
    final List<ProjectModel> all = <ProjectModel>[
      handingOver(1, 2029, 6),
      handingOver(2, 2026, 10), // this month: still upcoming
      handingOver(3, 2027, 3),
      handingOver(4, 2022, 5, ready: true),
      handingOver(5, null, null, ready: true),
      handingOver(6, 2025, 12, ready: true),
      handingOver(7, 2027, 3, extra: <String, dynamic>{'developer': 'Emaar'}), // same month as 3
    ];
    final RankingEngine engine = RankingEngine(all, now: testNow);

    test('soonest: upcoming nearest-first (incl. this month), then ready newest-first, then undated', () {
      expect(ids(engine.sort(all, ProjectSort.handoverSoonest)), <int>[2, 7, 3, 1, 6, 4, 5]);
    });

    test('latest: upcoming furthest-first, then ready, then undated', () {
      expect(ids(engine.sort(all, ProjectSort.handoverLatest)), <int>[1, 7, 3, 2, 6, 4, 5]);
    });

    test('same handover month: featured/better project first', () {
      final List<int> soonest = ids(engine.sort(all, ProjectSort.handoverSoonest));
      expect(soonest.indexOf(7), lessThan(soonest.indexOf(3)));
    });
  });

  // ------------------------------------------------------- handover filter
  group('handover filter', () {
    final ProjectsRepository repo = ProjectsRepository(ProjectsService(_NoApi()));
    final List<ProjectModel> all = <ProjectModel>[
      handingOver(1, 2026, 12),
      handingOver(2, 2027, 1),
      handingOver(3, 2027, 12),
      handingOver(4, 2028, 1),
      handingOver(5, 2030, 6),
      handingOver(6, 2022, 5, ready: true),
      handingOver(7, null, null),
    ];
    final RankingEngine engine = RankingEngine(all, now: testNow);
    List<int> run(ProjectFilter f) =>
        ids(repo.applyFilter(all, f, engine))..sort();

    test('no range: everything, undated included', () {
      expect(run(const ProjectFilter()), <int>[1, 2, 3, 4, 5, 6, 7]);
    });

    test('from only: that month onwards, inclusive', () {
      expect(run(ProjectFilter(handoverFrom: DateTime(2027, 12, 28))), <int>[3, 4, 5]);
    });

    test('to only: up to and including that month', () {
      expect(run(ProjectFilter(handoverTo: DateTime(2027, 12, 1))), <int>[1, 2, 3, 6]);
    });

    test('from + to: both ends inclusive, by month whatever the picked day', () {
      expect(run(ProjectFilter(handoverFrom: DateTime(2027, 1, 31), handoverTo: DateTime(2027, 12, 1))), <int>[2, 3]);
    });

    test('a single-month range', () {
      expect(run(ProjectFilter(handoverFrom: DateTime(2028, 1, 15), handoverTo: DateTime(2028, 1, 15))), <int>[4]);
    });

    test('undated projects drop out once a range is set', () {
      expect(run(ProjectFilter(handoverFrom: DateTime(2000))), isNot(contains(7)));
    });

    test('ready buildings match by their completion date', () {
      expect(run(ProjectFilter(handoverTo: DateTime(2023))), <int>[6]);
    });

    test('a range nothing falls in returns empty', () {
      expect(run(ProjectFilter(handoverFrom: DateTime(2031), handoverTo: DateTime(2032))), isEmpty);
    });

    test('combines with the Off-Plan tab, price and a handover sort', () {
      final List<ProjectModel> withPrices = <ProjectModel>[
        handingOver(1, 2026, 12, extra: <String, dynamic>{'min_price': 800000.0}),
        handingOver(2, 2027, 6, extra: <String, dynamic>{'min_price': 2500000.0}),
        handingOver(3, 2027, 2, extra: <String, dynamic>{'min_price': 1200000.0}),
        handingOver(4, 2026, 11, ready: true, extra: <String, dynamic>{'min_price': 900000.0}),
      ];
      final RankingEngine e = RankingEngine(withPrices, now: testNow);
      final List<ProjectModel> out = repo.applyFilter(
        withPrices,
        ProjectFilter(
          statusCode: 2,
          maxPrice: 2000000,
          handoverTo: DateTime(2027, 12),
          sort: ProjectSort.handoverSoonest,
        ),
        e,
      );
      expect(ids(out), <int>[1, 3]);
    });

    test('counts as an active filter (filter badge)', () {
      expect(ProjectFilter(handoverFrom: DateTime(2027)).hasActiveFilters, isTrue);
      expect(ProjectFilter(handoverTo: DateTime(2027)).hasActiveFilters, isTrue);
      expect(const ProjectFilter().hasActiveFilters, isFalse);
    });
  });

  group('filter controller', () {
    test('setHandoverRange sets, keeps one end, and clears', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final ProjectFilterController ctl = c.read(projectFilterProvider.notifier);
      ctl.setHandoverRange(DateTime(2027), DateTime(2028));
      expect(c.read(projectFilterProvider).handoverFrom, DateTime(2027));
      expect(c.read(projectFilterProvider).handoverTo, DateTime(2028));
      ctl.setHandoverRange(null, null);
      expect(c.read(projectFilterProvider).hasHandoverFilter, isFalse);
    });

    test('Reset clears the range and the sort but keeps the tab', () {
      final ProviderContainer c = ProviderContainer();
      addTearDown(c.dispose);
      final ProjectFilterController ctl = c.read(projectFilterProvider.notifier);
      ctl.setStatus(2);
      ctl.setHandoverRange(DateTime(2027), null);
      ctl.setSort(ProjectSort.handoverLatest);
      ctl.clearSheetFilters();
      final ProjectFilter f = c.read(projectFilterProvider);
      expect(f.hasHandoverFilter, isFalse);
      expect(f.sort, ProjectSort.bestMatch);
      expect(f.statusCode, 2);
    });
  });
}

/// The handover filter is pure — it never touches the network.
class _NoApi implements ApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
