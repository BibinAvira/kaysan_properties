import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/guest_gate.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../../models/auth_models.dart';
import '../../../providers/auth_provider.dart';
import '../../listings/widgets/filter_sheet.dart';

/// Which property-status bucket the Home "Top Property" list is filtered
/// to. `null` means "All". Kept local to Home rather than wired into the
/// full [ProjectFilter]/Listings filter stack, since this is a lightweight
/// at-a-glance toggle rather than the full filter sheet.
class HomeStatusFilterController extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? value) {
    state = value;
    if (value == null) return;
    // Only page 1 (now up to 100 items) is loaded by default. If none of
    // those happen to be e.g. "Ready" — plausible, since off-plan listings
    // dominate a newest-first feed — keep fetching further pages rather
    // than showing "no properties" for a status that does exist deeper in
    // the catalog. See ProjectFilterController._searchDeeperIfNeeded for
    // the same pattern on the Listings screen.
    ref.read(projectsProvider.notifier).loadUntilMatch(
          (List<ProjectModel> items) =>
              items.any((ProjectModel p) => p.propertyStatusCode == value),
        );
  }
}

final NotifierProvider<HomeStatusFilterController, int?>
    homeStatusFilterProvider =
    NotifierProvider<HomeStatusFilterController, int?>(
        HomeStatusFilterController.new);

/// Top of Home (client redesign, "Soft Gold Arcs"): soft gold circles in
/// the top-right corner behind the "Good morning, {name} 👋" greeting +
/// location + bell, the serif "Find Your Next Property" headline, and the
/// search bar with its filter button.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key});

  /// Prefers `fullName`'s first word, falls back to `username`.
  static String? _firstName(UserModel user) {
    final String? fullName = user.fullName;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(RegExp(r'\s+')).first;
    }
    if (user.username.trim().isNotEmpty) {
      return user.username.trim();
    }
    return null;
  }

  static String _timeOfDayGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final double topInset = MediaQuery.paddingOf(context).top;
    final String? firstName = ref.watch(authControllerProvider).maybeWhen(
          data: (UserModel? user) => user != null ? _firstName(user) : null,
          orElse: () => null,
        );
    final String greeting = firstName != null
        ? '${_timeOfDayGreeting()}, $firstName 👋'
        : '${_timeOfDayGreeting()} 👋';

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter:
                _GoldArcsPainter(dark: theme.brightness == Brightness.dark),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(greeting,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w400)),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.location_on,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('Dubai, UAE',
                                style: theme.textTheme.titleMedium),
                            const Icon(Icons.keyboard_arrow_down, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () async {
                      // Account-dependent for guests; there's no
                      // notifications center yet even for signed-in users.
                      if (await requireAuth(context, ref) && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("You're all caught up!")),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Find Your Next\nProperty',
                style: TextStyle(
                  fontFamily: 'DMSerifDisplay',
                  fontSize: 34,
                  height: 1.1,
                  color: theme.textTheme.displayMedium?.color,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 240,
                child: Text(
                  'Explore Dubai’s latest off-plan and ready properties.',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 28),
              const _HeroSearchRow(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Concentric soft-gold circles centred just off the top-right corner,
/// drawn in code (no image). Sized off the header's width so they keep the
/// same proportions on every phone.
class _GoldArcsPainter extends CustomPainter {
  const _GoldArcsPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.width / 320;
    final Offset center = Offset(size.width - 20 * unit, 40 * unit);
    if (dark) {
      // TEMP: dark-mode arcs disabled to preview the header without them.
      // _paintDark(canvas, center, unit);
      return;
    }
    // Light: opaque warm tints on the off-white page.
    const List<(double, Color)> discs = <(double, Color)>[
      (170, Color(0xFFF7EBD2)),
      (120, Color(0xFFF2DDB0)),
      (72, Color(0xFFE9C98A)),
    ];
    for (final (double radius, Color color) in discs) {
      canvas.drawCircle(center, radius * unit, Paint()..color = color);
    }
    canvas.drawCircle(
      center,
      200 * unit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.goldLight.withValues(alpha: 0.6),
    );
  }

  /// Dark: the same stepped discs as light, in [AppColors.gold]'s own hue
  /// at decreasing lightness. (Blending gold into the blue-tinted
  /// [AppColors.scaffoldDark] instead greyed the outer discs to olive.)
  void _paintDark(Canvas canvas, Offset center, double unit) {
    const List<(double, Color)> discs = <(double, Color)>[
      (170, Color(0xFF3F3112)),
      (120, Color(0xFF6A501B)),
      (72, Color(0xFF8D6A20)),
    ];
    for (final (double radius, Color color) in discs) {
      canvas.drawCircle(center, radius * unit, Paint()..color = color);
    }
    canvas.drawCircle(
      center,
      200 * unit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.goldLight.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_GoldArcsPainter oldDelegate) => oldDelegate.dark != dark;
}

/// Solid white rounded search field + round filter button. Both carry the
/// All / Off-Plan / Ready pill picked on Home ([homeStatusFilterProvider])
/// over to their results, so picking Ready then searching or filtering
/// shows Ready properties only.
class _HeroSearchRow extends ConsumerWidget {
  const _HeroSearchRow();

  void _carryStatusPill(WidgetRef ref) => ref
      .read(projectFilterProvider.notifier)
      .setStatus(ref.read(homeStatusFilterProvider));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Material(
            color: theme.cardColor,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                _carryStatusPill(ref);
                context.push(RouteNames.search);
              },
              child: SizedBox(
                height: 56,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 18),
                    const Icon(Icons.search,
                        color: AppColors.textSecondaryLight),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        'Search projects, locations, developers...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        RoundIconButton(
          icon: Icons.tune_rounded,
          size: 56,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            // Above the tab shell, so the floating nav bar doesn't cover
            // the sheet or inflate its bottom safe-area padding.
            useRootNavigator: true,
            isScrollControlled: true,
            showDragHandle: true,
            // `sheetContext` is gone once the sheet closes, so the
            // navigation after "Show Results" uses Home's own `context`.
            builder: (BuildContext sheetContext) => FilterSheet(
              onShowResults: () {
                _carryStatusPill(ref);
                // Switch to the Projects tab (on the matching status tab)
                // rather than stacking another listings screen on Home.
                context.go(RouteNames.listings);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// All / Off-Plan / Ready tabs above "Top Property" — the shared
/// [StatusTabs] bound to [homeStatusFilterProvider].
class HomeCategoryChips extends ConsumerWidget {
  const HomeCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StatusTabs(
      selected: ref.watch(homeStatusFilterProvider),
      onChanged: (int? status) =>
          ref.read(homeStatusFilterProvider.notifier).set(status),
    );
  }
}
