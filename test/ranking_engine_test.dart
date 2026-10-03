import 'package:flutter_test/flutter_test.dart';
import 'package:kaysan_properties/models/project_model.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import 'package:kaysan_properties/repositories/ranking_engine.dart';

import 'support/project_factory.dart';

void main() {
  test('unlistable projects are dropped', () {
    final List<ProjectModel> all = <ProjectModel>[
      project(1),
      project(2, <String, dynamic>{'sale_status': 'out_of_stock'}),
      project(3, <String, dynamic>{'cover_image': null}),
      project(4, <String, dynamic>{'min_price': 0.0, 'min_size': 0.0}),
      project(5, <String, dynamic>{'name': 'Test Tower'}),
      // Off-plan whose handover has already passed: stale data.
      project(6, <String, dynamic>{'completion_datetime': '2024-01-31T00:00:00Z'}),
    ];
    final List<int> ids = RankingEngine(all, now: testNow).rank(all).map((ProjectModel p) => p.id).toList();
    expect(ids, <int>[1]);
  });

  test('a fresh launch outranks an old one; old buildings sink', () {
    final ProjectModel fresh = project(1);
    final ProjectModel old = project(2, <String, dynamic>{
      'construction_status': 'completed',
      'construction_start_date': '2007-02-01',
      'completion_datetime': '2010-12-07T00:00:00Z',
    });
    final RankingEngine engine = RankingEngine(<ProjectModel>[fresh, old], now: testNow);
    expect(engine.rank(<ProjectModel>[old, fresh]).first.id, 1);
  });

  test('featured boosts among equals but cannot keep a stale project on top', () {
    final ProjectModel featuredFresh = project(1, <String, dynamic>{'developer': 'Emaar'});
    final ProjectModel plainFresh = project(2);
    final ProjectModel featuredOld = project(3, <String, dynamic>{
      'developer': 'Emaar',
      'construction_start_date': '2023-01-01',
    });
    final List<ProjectModel> all = <ProjectModel>[featuredOld, plainFresh, featuredFresh];
    final List<int> ids = RankingEngine(all, now: testNow).rank(all).map((ProjectModel p) => p.id).toList();
    expect(ids, <int>[1, 2, 3]);
  });

  test('no more than two cards in a row from one developer', () {
    final List<ProjectModel> all = <ProjectModel>[
      for (int i = 1; i <= 4; i++) project(i, <String, dynamic>{'developer': 'Emaar'}),
      project(10),
    ];
    final List<String> devs =
        RankingEngine(all, now: testNow).rank(all).map((ProjectModel p) => p.developer.name).toList();
    expect(devs.take(3).toSet().length, greaterThan(1));
  });

  test('duplicates collapse to the better copy', () {
    // Ids spread like the real catalogue's, so the two copies (listed
    // close together) differ on completeness, not listing recency.
    final ProjectModel complete =
        project(500, <String, dynamic>{'name': 'Sky Tower', 'developer': 'X'});
    final ProjectModel partial = project(501,
        <String, dynamic>{'name': 'Sky  Tower!', 'developer': 'X', 'min_bedrooms': null, 'max_bedrooms': null});
    final List<ProjectModel> all = <ProjectModel>[project(1), complete, partial, project(4000)];
    final List<ProjectModel> ranked = RankingEngine(all, now: testNow).rank(all);
    expect(ranked.map((ProjectModel p) => p.id), containsAll(<int>[500]));
    expect(ranked.map((ProjectModel p) => p.id), isNot(contains(501)));
  });

  test('price sort puts unpriced projects last', () {
    final List<ProjectModel> all = <ProjectModel>[
      project(1, <String, dynamic>{'min_price': 0.0}),
      project(2, <String, dynamic>{'min_price': 900000.0}),
    ];
    final RankingEngine engine = RankingEngine(all, now: testNow);
    expect(engine.sort(all, ProjectSort.priceLowToHigh).map((ProjectModel p) => p.id), <int>[2, 1]);
  });

  test('handover sorts: upcoming first (nearest or furthest), then ready, then undated', () {
    ProjectModel h(int id, String? date, {bool ready = false}) => project(id, <String, dynamic>{
          'completion_datetime': date,
          'construction_end_date': date,
          'construction_status': ready ? 'completed' : 'under_construction',
        });
    final List<ProjectModel> all = <ProjectModel>[
      h(1, '2029-06-30T00:00:00Z'),
      h(2, '2026-12-31T00:00:00Z'),
      h(3, '2027-03-31T00:00:00Z'),
      h(4, '2022-05-01T00:00:00Z', ready: true),
      h(5, null, ready: true),
    ];
    final RankingEngine engine = RankingEngine(all, now: testNow);
    expect(engine.sort(all, ProjectSort.handoverSoonest).map((ProjectModel p) => p.id), <int>[2, 3, 1, 4, 5]);
    expect(engine.sort(all, ProjectSort.handoverLatest).map((ProjectModel p) => p.id), <int>[1, 3, 2, 4, 5]);
  });
}
