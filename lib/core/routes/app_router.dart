import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../views/about/about_view.dart';
import '../../views/areas/areas_view.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/profile_view.dart';
import '../../views/auth/register_view.dart';
import '../../views/blogs/blogs_view.dart';
import '../../views/calculator/calculator_view.dart';
import '../../views/common/common_views.dart';
import '../../views/contact/contact_view.dart';
import '../../views/developers/developer_details_view.dart';
import '../../views/favorites/favorites_view.dart';
import '../../views/home/home_view.dart';
import '../../views/legal/legal_views.dart';
import '../../views/listings/listings_view.dart';
import '../../views/more/more_view.dart';
import '../../views/property_details/property_details_view.dart';
import '../../views/search/search_view.dart';
import '../../views/shell/main_shell.dart';
import '../../views/splash/splash_view.dart';
import 'route_names.dart';

/// Root navigation graph. A [StatefulShellRoute] hosts the four bottom-nav
/// tabs (Home / Listings / Favorites / More), each keeping its own stack;
/// everything else (Property Details, Search, Areas, Blogs, Contact, Legal)
/// is pushed on top via ordinary [GoRoute]s so it covers the bottom nav.
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.contact, // TEMP: dark-mode visual QA, reverting after
  errorBuilder: (BuildContext context, GoRouterState state) =>
      AppErrorView(message: 'Page not found: ${state.uri}'),
  routes: <RouteBase>[
    GoRoute(path: RouteNames.splash, builder: (BuildContext context, GoRouterState state) => const SplashView()),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: RouteNames.home, builder: (BuildContext context, GoRouterState state) => const HomeView()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: RouteNames.listings, builder: (BuildContext context, GoRouterState state) => const ListingsView()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: RouteNames.favorites, builder: (BuildContext context, GoRouterState state) => const FavoritesView()),
        ]),
        StatefulShellBranch(routes: <RouteBase>[
          GoRoute(path: '/more', builder: (BuildContext context, GoRouterState state) => const MoreView()),
        ]),
      ],
    ),
    GoRoute(
      path: RouteNames.search,
      builder: (BuildContext context, GoRouterState state) => const SearchView(),
    ),
    GoRoute(
      path: RouteNames.propertyDetails,
      builder: (BuildContext context, GoRouterState state) {
        final int id = int.parse(state.pathParameters['id']!);
        return PropertyDetailsView(projectId: id);
      },
    ),
    GoRoute(
      path: RouteNames.areas,
      builder: (BuildContext context, GoRouterState state) => const AreasView(),
    ),
    GoRoute(
      path: RouteNames.areaDetails,
      builder: (BuildContext context, GoRouterState state) {
        final int id = int.parse(state.pathParameters['id']!);
        return AreaDetailsView(districtId: id);
      },
    ),
    GoRoute(
      path: RouteNames.developerDetails,
      builder: (BuildContext context, GoRouterState state) {
        final int id = int.parse(state.pathParameters['id']!);
        return DeveloperDetailsView(developerId: id);
      },
    ),
    GoRoute(
      path: RouteNames.blogs,
      builder: (BuildContext context, GoRouterState state) => const BlogsView(),
    ),
    GoRoute(
      path: RouteNames.blogDetails,
      builder: (BuildContext context, GoRouterState state) {
        final int id = int.parse(state.pathParameters['id']!);
        return BlogDetailsView(blogId: id);
      },
    ),
    GoRoute(
      path: RouteNames.calculator,
      builder: (BuildContext context, GoRouterState state) {
        final double? initialPrice = state.extra as double?;
        return CalculatorView(initialPrice: initialPrice);
      },
    ),
    GoRoute(path: RouteNames.contact, builder: (BuildContext context, GoRouterState state) => const ContactView()),
    GoRoute(path: RouteNames.about, builder: (BuildContext context, GoRouterState state) => const AboutView()),
    GoRoute(path: RouteNames.privacyPolicy, builder: (BuildContext context, GoRouterState state) => const PrivacyPolicyView()),
    GoRoute(path: RouteNames.terms, builder: (BuildContext context, GoRouterState state) => const TermsView()),
    GoRoute(path: RouteNames.noInternet, builder: (BuildContext context, GoRouterState state) => const NoInternetView()),
    GoRoute(
      path: RouteNames.login,
      builder: (BuildContext context, GoRouterState state) =>
          LoginView(prefillUsername: state.extra as String?),
    ),
    GoRoute(
      path: RouteNames.register,
      builder: (BuildContext context, GoRouterState state) => const RegisterView(),
    ),
    GoRoute(
      path: RouteNames.profile,
      builder: (BuildContext context, GoRouterState state) => const ProfileView(),
    ),
  ],
);

/// Riverpod provider so the router can later be made reactive to auth
/// state (e.g. via `refreshListenable`) without changing call sites.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) => appRouter);
