import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/guest_gate.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../providers/projects_provider.dart';
import '../../../widgets/glass/liquid_glass.dart';
import '../../../models/auth_models.dart';
import '../../../providers/auth_provider.dart';
import '../../listings/widgets/filter_sheet.dart';

/// Icon color for a [LiquidGlassCircle] sitting directly on the page
/// background (as opposed to over a photo, where white is always correct
/// regardless of theme) — the glass tint itself stays a light frost in
/// both themes, but a near-black icon on it disappears once that frost
/// sits over a dark page, since the backdrop blur lets the dark page show
/// through. Picking the icon color from the current theme's brightness
/// keeps it visible either way.
Color _glassIconColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppColors.textPrimaryDark
      : AppColors.textPrimaryLight;
}

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
          (List<ProjectModel> items) => items.any((ProjectModel p) => p.propertyStatusCode == value),
        );
  }
}

final NotifierProvider<HomeStatusFilterController, int?>
    homeStatusFilterProvider =
    NotifierProvider<HomeStatusFilterController, int?>(
        HomeStatusFilterController.new);

/// "Hi {FirstName} 👋" greeting (name bolded) + location row + notification
/// bell, replacing the plain app bar title. Greeting pulls the first name
/// from [authControllerProvider] when logged in, falling back to a plain
/// "Hello 👋" when logged out.
class HomeGreetingHeader extends ConsumerWidget {
  const HomeGreetingHeader({super.key});

  /// Extracts a display-friendly first name from the user model.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<UserModel?> authState = ref.watch(authControllerProvider);

    final String? firstName = authState.maybeWhen(
      data: (UserModel? user) => user != null ? _firstName(user) : null,
      orElse: () => null,
    );

    // titleMedium rather than bodyMedium: the greeting was easy to miss
    // at bodyMedium's 14px + secondary/muted gray color — titleMedium is
    // both bigger (16px) and uses the primary text color.
    final TextStyle? baseStyle = theme.textTheme.titleMedium;
    // Bold weight only — color stays whatever baseStyle already carries
    // (correctly light-in-dark-mode / dark-in-light-mode via the theme's
    // own text styles). This used to hardcode Colors.black, which made
    // the greeting unreadable in dark mode.
    final TextStyle? emphasisStyle = baseStyle?.copyWith(fontWeight: FontWeight.bold);
    final Widget greeting = firstName != null
        ? Text.rich(
            TextSpan(
              style: baseStyle,
              children: <InlineSpan>[
                TextSpan(text: 'Hi ', style: emphasisStyle),
                TextSpan(text: firstName, style: emphasisStyle),
                const TextSpan(text: ' 👋'),
              ],
            ),
          )
        : Text('Hello 👋', style: baseStyle);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                greeting,
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.gold),
                    const SizedBox(width: 2),
                    Text('Dubai, UAE', style: theme.textTheme.titleMedium),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ],
            ),
          ),
          LiquidGlassCircle(
            icon: Icons.notifications_none_rounded,
            iconColor: _glassIconColor(context),
            onTap: () async {
              // Personalized notifications are an account-dependent
              // feature for guests. There's no notifications center built
              // yet even for signed-in users, so this is as far as it
              // goes today — but the gate is already wired for when there
              // is one.
              if (await requireAuth(context, ref) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You're all caught up!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// The bold "Explore Modern Living Spaces Near You"-style headline.
class HomeHeadline extends StatelessWidget {
  const HomeHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.displayMedium;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text.rich(
        TextSpan(
          style: style?.copyWith(fontWeight: FontWeight.w500),
          children: <InlineSpan>[
            const TextSpan(text: 'Explore '),
            TextSpan(
              text: 'Off-Plan Properties',
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
            const TextSpan(text: ' in Dubai'),
          ],
        ),
      ),
    );
  }
}

/// Rounded search field + filter button, matching the Figma search row.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => context.push(RouteNames.search),
              child: LiquidGlass(
                borderRadius: 26,
                blur: 26,
                tintOpacity: 0.55,
                borderOpacity: 0.5,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.search,
                        color: AppColors.textSecondaryLight),
                    const SizedBox(width: 10),
                    Text('Search',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          LiquidGlassCircle(
            icon: Icons.tune_rounded,
            iconColor: _glassIconColor(context),
            tintOpacity: 0.55,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (BuildContext context) => FilterSheet(
                onShowResults: () => context.push(RouteNames.listings),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Apartment / Ready / Off-Plan" style pill row. Maps onto the real
/// [ProjectModel.propertyStatusCode] the API already exposes (1 = Ready,
/// 2 = Off-Plan) rather than inventing categories the data can't back up.
class HomeCategoryChips extends ConsumerWidget {
  const HomeCategoryChips({super.key});

  static const List<(String, int?)> _options = <(String, int?)>[
    ('All Projects', null),
    ('Ready', 1),
    ('Off-Plan', 2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? selected = ref.watch(homeStatusFilterProvider);
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _options.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final (String label, int? value) = _options[index];
          final bool active = selected == value;
          return GestureDetector(
            onTap: () => ref.read(homeStatusFilterProvider.notifier).set(value),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              child: active
                  ? Container(
                      key: const ValueKey<bool>(true),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : LiquidGlass(
                      key: const ValueKey<bool>(false),
                      borderRadius: 22,
                      blur: 24,
                      tintOpacity: 0.5,
                      borderOpacity: 0.45,
                      shadow: false,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
