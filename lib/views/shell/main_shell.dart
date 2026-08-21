import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/network_provider.dart';
import '../../widgets/glass/liquid_glass.dart';

/// Shared shell for the four primary tabs. GoRouter's [StatefulShellRoute]
/// keeps each tab's own navigation stack alive across switches, matching
/// standard mobile-app tab behaviour.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_TabItem> _tabs = <_TabItem>[
    _TabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home'),
    _TabItem(
        icon: Icons.apartment_outlined,
        activeIcon: Icons.apartment_rounded,
        label: 'Listings'),
    _TabItem(
        icon: Icons.favorite_border,
        activeIcon: Icons.favorite_rounded,
        label: 'Favorites'),
    _TabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'More'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> network = ref.watch(networkStatusProvider);
    final bool offline =
        network.maybeWhen(data: (bool v) => !v, orElse: () => false);

    return Scaffold(
      extendBody: true,
      body: Column(
        children: <Widget>[
          if (offline) const _OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _FloatingGlassNavBar(
        currentIndex: navigationShell.currentIndex,
        tabs: _tabs,
        onSelect: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Floating "Liquid Glass" pill nav bar matching the reference design:
/// a frosted glass capsule hovering above the content with an animated
/// solid-black puck sliding behind whichever destination is selected.
class _FloatingGlassNavBar extends StatelessWidget {
  const _FloatingGlassNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
  });

  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onSelect;

  static const Duration _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: LiquidGlass(
        borderRadius: 36,
        blur: 32,
        tintOpacity: 0.16,
        borderOpacity: 0.3,
        height: 74,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double itemWidth = constraints.maxWidth / tabs.length;
            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                AnimatedPositioned(
                  duration: _duration,
                  curve: _curve,
                  left: itemWidth * currentIndex + (itemWidth - 52) / 2,
                  top: 11,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(tabs.length, (int index) {
                    final bool selected = index == currentIndex;
                    final _TabItem tab = tabs[index];
                    return Expanded(
                      child: InkWell(
                        onTap: () => onSelect(index),
                        borderRadius: BorderRadius.circular(36),
                        child: SizedBox(
                          height: 74,
                          child: Center(
                            child: AnimatedScale(
                              duration: _duration,
                              curve: _curve,
                              scale: selected ? 1.08 : 1,
                              child: AnimatedOpacity(
                                duration: _duration,
                                curve: _curve,
                                opacity: selected ? 1 : 0.65,
                                child: Icon(
                                  selected ? tab.activeIcon : tab.icon,
                                  color: selected
                                      ? Colors.white
                                      : (isDark ? Colors.white : Colors.black),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem(
      {required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No internet connection — showing cached content',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
