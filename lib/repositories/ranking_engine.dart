import 'dart:math' as math;

import '../models/project_model.dart';
import 'projects_repository.dart' show ProjectSort, featuredDeveloperIds;

/// Points per signal in a project's "Best Match" score (0–100). Reelly has
/// no views, favourites, verification or agent data, so the score is built
/// only from what every `/projects` list record carries — see the
/// per-weight notes below for why each one exists and how big it is.
class RankingWeights {
  RankingWeights._();

  /// Launch recency: `launchFreshness × 0.5^(launch age / [launchHalfLife])`.
  /// A 12-month half-life puts a launch from this year near 22, a two-year-
  /// old one near 6 and a 2015 one near 0, so old buildings sink without
  /// a hard cut-off.
  static const double launchFreshness = 22;
  static const int launchHalfLifeMonths = 12;

  /// How recently the record was added to Reelly (its id, linearly). Breaks
  /// the many ties among projects whose estimated launch is "now", and
  /// rewards new listings without letting an old building added last week
  /// win on this alone (it's under half of [launchFreshness]).
  static const double listingRecency = 8;

  /// Presale / announced / start of sales — the most sought-after stock.
  static const double newLaunch = 5;

  /// The client's featured developers. Big enough to lead among equally
  /// fresh projects, too small to keep a stale one on top: a two-year-old
  /// featured launch (≈6 + 8) loses to a fresh non-featured one (≈30).
  static const double featuredDeveloper = 8;
  static const double partnerProject = 4;

  /// Completeness — what a buyer needs to judge a listing. Price matters
  /// most, so it carries the most.
  static const double hasPrice = 5;
  static const double hasSize = 3;
  static const double hasBedrooms = 3;
  static const double hasDistrict = 3;
  static const double hasHandover = 3;
  static const double hasUnitTypes = 2;
  static const double hasStartDate = 1;

  /// Cover photo — it *is* the card. By pixel width.
  static const double sharpCover = 10; // ≥ 1200px
  static const double okCover = 6; // ≥ 800px
  static const double softCover = 2; // smaller / unknown

  /// Recently maintained: `activity × 0.5^(days since update / 30)`. Kept
  /// small: Reelly touches most records every few weeks, so this mostly
  /// separates neglected listings from the rest.
  static const double activity = 10;
  static const int activityHalfLifeDays = 30;

  /// "Curated" pass: at most this many cards in a row from one developer.
  static const int maxSameDeveloperRun = 2;
  static const int diversityLookahead = 6;
}

/// One project's score, split by signal so the ranking can be explained.
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.freshness,
    required this.newLaunch,
    required this.priority,
    required this.completeness,
    required this.quality,
    required this.activity,
  });

  final double freshness;
  final double newLaunch;
  final double priority;
  final double completeness;
  final double quality;
  final double activity;

  double get total =>
      freshness + newLaunch + priority + completeness + quality + activity;

  @override
  String toString() => '${total.toStringAsFixed(1)} = '
      'fresh ${freshness.toStringAsFixed(1)}, launch $newLaunch, '
      'priority $priority, complete $completeness, image $quality, '
      'active ${activity.toStringAsFixed(1)}';
}

/// Scores and orders projects. Built once per catalogue load (scores are
/// cached per id), so every filter/sort afterwards is a plain in-memory
/// sort.
class RankingEngine {
  RankingEngine(Iterable<ProjectModel> catalog, {DateTime? now})
      : _now = now ?? DateTime.now() {
    final List<ProjectModel> all = catalog.toList();
    if (all.isNotEmpty) {
      _minId = all.map((ProjectModel p) => p.id).reduce(math.min);
      _maxId = all.map((ProjectModel p) => p.id).reduce(math.max);
    }
    _buildMonths = _medianBuildMonths(all) ?? _buildMonths;
  }

  final DateTime _now;
  int _minId = 0;
  int _maxId = 0;

  /// Typical start-to-handover duration, measured from the catalogue
  /// (34 months on Reelly's data) — used to estimate a launch date for
  /// projects without `construction_start_date`.
  int _buildMonths = 34;

  final Map<int, ScoreBreakdown> _scores = <int, ScoreBreakdown>{};

  static final RegExp _testName =
      RegExp(r'\b(test|demo|sample|dummy)\b', caseSensitive: false);

  /// Whether [p] may be listed at all: nothing sold out, stale, without a
  /// photo, without both price and size, or test/demo data.
  static bool isListable(ProjectModel p) =>
      !p.isSoldOut &&
      !p.isStaleOffPlan &&
      p.cover.isNotEmpty &&
      (p.lowPrice > 0 || p.minArea > 0) &&
      !_testName.hasMatch(p.title.display);

  ScoreBreakdown scoreOf(ProjectModel p) =>
      _scores.putIfAbsent(p.id, () => _score(p));

  /// [listable] projects, duplicates (same name + developer) collapsed to
  /// the best-scoring copy, in [ProjectSort.bestMatch] order.
  List<ProjectModel> rank(Iterable<ProjectModel> projects) {
    final Map<String, ProjectModel> unique = <String, ProjectModel>{};
    for (final ProjectModel p in projects.where(isListable)) {
      final String key =
          '${_normalize(p.title.display)}|${_normalize(p.developer.name)}';
      final ProjectModel? existing = unique[key];
      if (existing == null ||
          scoreOf(p).total > scoreOf(existing).total) {
        unique[key] = p;
      }
    }
    return sort(unique.values, ProjectSort.bestMatch);
  }

  /// [projects] in [sort] order. Every sort falls back to Best Match for
  /// ties, so the order is always deterministic.
  List<ProjectModel> sort(Iterable<ProjectModel> projects, ProjectSort sort) {
    final List<ProjectModel> list = projects.toList();
    int byBest(ProjectModel a, ProjectModel b) => _compareBest(a, b);
    switch (sort) {
      case ProjectSort.bestMatch:
        list.sort(byBest);
        return _diversify(list);
      case ProjectSort.newest:
        list.sort((ProjectModel a, ProjectModel b) {
          final int c = _launchDate(b).compareTo(_launchDate(a));
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.recentlyUpdated:
        list.sort((ProjectModel a, ProjectModel b) {
          final int c = (b.updatedAt ?? DateTime(1970))
              .compareTo(a.updatedAt ?? DateTime(1970));
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.priceLowToHigh:
        list.sort((ProjectModel a, ProjectModel b) {
          // Unpriced ("On Request") last, not first.
          if ((a.lowPrice <= 0) != (b.lowPrice <= 0)) {
            return a.lowPrice <= 0 ? 1 : -1;
          }
          final int c = a.lowPrice.compareTo(b.lowPrice);
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.priceHighToLow:
        list.sort((ProjectModel a, ProjectModel b) {
          final int c = b.lowPrice.compareTo(a.lowPrice);
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.handoverSoonest:
      case ProjectSort.handoverLatest:
        final bool soonest = sort == ProjectSort.handoverSoonest;
        final int thisMonth = _now.year * 100 + _now.month;
        // Upcoming handovers first (nearest or furthest, as asked), then
        // ready/past ones (most recent first), then undated.
        int group(ProjectModel p) => p.deliveryDate <= 0
            ? 2
            : p.deliveryDate < thisMonth
                ? 1
                : 0;
        list.sort((ProjectModel a, ProjectModel b) {
          final int ga = group(a);
          final int gb = group(b);
          if (ga != gb) return ga.compareTo(gb);
          int c = 0;
          if (ga == 0) {
            c = soonest
                ? a.deliveryDate.compareTo(b.deliveryDate)
                : b.deliveryDate.compareTo(a.deliveryDate);
          } else if (ga == 1) {
            c = b.deliveryDate.compareTo(a.deliveryDate);
          }
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.largestArea:
        list.sort((ProjectModel a, ProjectModel b) {
          final int c = _plausibleArea(b).compareTo(_plausibleArea(a));
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.bedrooms:
        list.sort((ProjectModel a, ProjectModel b) {
          final int c = (_plausibleBedrooms(b) ?? -1)
              .compareTo(_plausibleBedrooms(a) ?? -1);
          return c != 0 ? c : byBest(a, b);
        });
      case ProjectSort.readyToMove:
        list.sort((ProjectModel a, ProjectModel b) {
          final bool ra = a.propertyStatusCode == 1;
          if (ra != (b.propertyStatusCode == 1)) return ra ? -1 : 1;
          return byBest(a, b);
        });
      case ProjectSort.featured:
        list.sort((ProjectModel a, ProjectModel b) {
          final bool fa = isFeatured(a);
          if (fa != isFeatured(b)) return fa ? -1 : 1;
          return byBest(a, b);
        });
    }
    return list;
  }

  /// Reelly occasionally sends impossible sizes/bedroom counts (one office
  /// project claims a 1.7M sq.ft unit, one tower 20 bedrooms) that would
  /// otherwise top the Largest area / Most bedrooms sorts. The biggest real
  /// units in the catalogue are ~43,000 sq.ft and 8 bedrooms.
  static const double maxPlausibleAreaSqft = 100000;
  static const int maxPlausibleBedrooms = 12;

  /// The largest believable unit size: [ProjectModel.maxArea], else
  /// [ProjectModel.minArea], ignoring impossible values (0 if neither).
  static double _plausibleArea(ProjectModel p) {
    bool ok(double v) => v > 0 && v <= maxPlausibleAreaSqft;
    if (ok(p.maxArea)) return p.maxArea;
    return ok(p.minArea) ? p.minArea : 0;
  }

  static int? _plausibleBedrooms(ProjectModel p) {
    final int? beds = p.maxBedrooms;
    return beds != null && beds <= maxPlausibleBedrooms ? beds : null;
  }

  static bool isFeatured(ProjectModel p) =>
      featuredDeveloperIds.contains(p.developer.id);

  /// Score, then completeness, then most recently updated, then newest id.
  int _compareBest(ProjectModel a, ProjectModel b) {
    final ScoreBreakdown sa = scoreOf(a);
    final ScoreBreakdown sb = scoreOf(b);
    int c = sb.total.compareTo(sa.total);
    if (c != 0) return c;
    c = sb.completeness.compareTo(sa.completeness);
    if (c != 0) return c;
    c = (b.updatedAt ?? DateTime(1970)).compareTo(a.updatedAt ?? DateTime(1970));
    if (c != 0) return c;
    return b.id.compareTo(a.id);
  }

  ScoreBreakdown _score(ProjectModel p) {
    final int ageMonths = math.max(0, _monthsBetween(_launchDate(p), _now));
    final double idRecency =
        _maxId > _minId ? ((p.id - _minId) / (_maxId - _minId)).clamp(0, 1) : 0;
    final double freshness = RankingWeights.launchFreshness *
            math.pow(0.5, ageMonths / RankingWeights.launchHalfLifeMonths) +
        RankingWeights.listingRecency * idRecency;

    final double priority =
        (isFeatured(p) ? RankingWeights.featuredDeveloper : 0) +
            (p.isPartnerProject ? RankingWeights.partnerProject : 0);

    final double completeness = (p.lowPrice > 0 ? RankingWeights.hasPrice : 0) +
        (p.minArea > 0 ? RankingWeights.hasSize : 0) +
        (p.subunitCount.value.isNotEmpty ? RankingWeights.hasBedrooms : 0) +
        (p.district.name.display.isNotEmpty ? RankingWeights.hasDistrict : 0) +
        (p.deliveryDate > 0 ? RankingWeights.hasHandover : 0) +
        (p.propertyType.isNotEmpty ? RankingWeights.hasUnitTypes : 0) +
        (p.constructionStartDate != null ? RankingWeights.hasStartDate : 0);

    final double quality = p.coverWidth >= 1200
        ? RankingWeights.sharpCover
        : p.coverWidth >= 800
            ? RankingWeights.okCover
            : RankingWeights.softCover;

    final DateTime? updated = p.updatedAt;
    final double activity = updated == null
        ? 0
        : RankingWeights.activity *
            math.pow(
                0.5,
                math.max(0, _now.difference(updated).inDays) /
                    RankingWeights.activityHalfLifeDays);

    return ScoreBreakdown(
      freshness: freshness,
      newLaunch: p.isNewLaunch ? RankingWeights.newLaunch : 0,
      priority: priority,
      completeness: completeness,
      quality: quality,
      activity: activity.toDouble(),
    );
  }

  /// `construction_start_date`, else handover minus the typical build time
  /// (never later than now), else ten years ago — so an undated project
  /// gets no freshness credit rather than all of it.
  DateTime _launchDate(ProjectModel p) {
    final DateTime? start = p.constructionStartDate;
    if (start != null) return start;
    final DateTime? handover = p.handoverDate;
    if (handover != null) {
      final DateTime estimate =
          DateTime(handover.year, handover.month - _buildMonths);
      return estimate.isAfter(_now) ? _now : estimate;
    }
    return DateTime(_now.year - 10, _now.month);
  }

  /// Greedy re-order so no developer fills more than
  /// [RankingWeights.maxSameDeveloperRun] cards in a row, pulling the next
  /// best other-developer project from a short look-ahead window — so the
  /// order barely moves, it just stops stacking.
  static List<ProjectModel> _diversify(List<ProjectModel> sorted) {
    final List<ProjectModel> pool = List<ProjectModel>.of(sorted);
    final List<ProjectModel> out = <ProjectModel>[];
    const int run = RankingWeights.maxSameDeveloperRun;
    while (pool.isNotEmpty) {
      int pick = 0;
      if (out.length >= run) {
        final String last = out.last.developer.name;
        final bool stacked = out
            .sublist(out.length - run)
            .every((ProjectModel p) => p.developer.name == last);
        if (stacked) {
          final int window =
              math.min(pool.length, RankingWeights.diversityLookahead);
          for (int i = 0; i < window; i++) {
            if (pool[i].developer.name != last) {
              pick = i;
              break;
            }
          }
        }
      }
      out.add(pool.removeAt(pick));
    }
    return out;
  }

  static int? _medianBuildMonths(List<ProjectModel> all) {
    final List<int> durations = <int>[
      for (final ProjectModel p in all)
        if (p.constructionStartDate != null && p.handoverDate != null)
          _monthsBetween(p.constructionStartDate!, p.handoverDate!),
    ]..removeWhere((int m) => m <= 0);
    if (durations.length < 20) return null;
    durations.sort();
    return durations[durations.length ~/ 2];
  }

  static int _monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
