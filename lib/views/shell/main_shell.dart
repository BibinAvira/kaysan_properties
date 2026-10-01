import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/network_provider.dart';

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
        label: 'Projects'),
    _TabItem(
        icon: Icons.favorite_border,
        activeIcon: Icons.favorite_rounded,
        label: 'Favorites'),
    _TabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> network = ref.watch(networkStatusProvider);
    final bool offline =
        network.maybeWhen(data: (bool v) => !v, orElse: () => false);

    return Scaffold(
      // Not extendBody: the bar sits below the content instead of
      // floating over (and hiding) the last items of every page.
      extendBody: false,
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

/// Rounded white bottom bar (client redesign): every tab shows its icon
/// and label; the selected tab's icon sits in a black circle.
class _FloatingGlassNavBar extends StatelessWidget {
  const _FloatingGlassNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onSelect,
  });

  final int currentIndex;
  final List<_TabItem> tabs;
  final ValueChanged<int> onSelect;

  static const Duration _duration = Duration(milliseconds: 250);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color idle = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Material(
          color: theme.cardColor,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(32),
          child: SizedBox(
            height: 66,
            child: Row(
              children: List<Widget>.generate(tabs.length, (int index) {
                final bool selected = index == currentIndex;
                final _TabItem tab = tabs[index];
                return Expanded(
                  child: InkWell(
                    onTap: () => onSelect(index),
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: _duration,
                          curve: _curve,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? (isDark ? Colors.white : Colors.black)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selected ? tab.activeIcon : tab.icon,
                            size: 20,
                            color: selected
                                ? (isDark ? Colors.black : Colors.white)
                                : idle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? theme.textTheme.titleMedium?.color
                                : idle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
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
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
