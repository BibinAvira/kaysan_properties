import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

/// A "Section Title" + optional "See all" action, used throughout Home.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.headlineSmall),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              // Compact: the default 48px-tall tap target made every
              // section header noticeably taller than its title.
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(actionLabel!,
                      style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.gold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Cached network image with a shimmer placeholder and a graceful broken
/// image fallback — used everywhere a remote photo is shown.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (BuildContext context, String _) => Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: Colors.white,
        child: Container(color: Colors.white),
      ),
      errorWidget: (BuildContext context, String _, Object __) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.divider,
        child: const Icon(Icons.apartment, color: AppColors.textSecondaryLight, size: 32),
      );
}

/// Generic empty/error/no-connection illustration + message + optional CTA.
/// Reused for empty states, error screens and the no-internet screen so
/// they share one visual language.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onActionTap, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Consistent transparent app bar used across secondary screens.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Round white button with a soft shadow — the filter/notification buttons
/// beside the Home and Listings search bars.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton(
      {super.key, required this.icon, required this.onTap, this.size = 48});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon,
              size: 24,
              color:
                  dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        ),
      ),
    );
  }
}

/// All / Off-Plan / Ready segmented tabs (Home and the Projects page).
/// Values are [ProjectModel.propertyStatusCode]s — 1 = Ready (`completed`),
/// 2 = Off-Plan (`under_construction` / `presale`), null = All. There's no
/// resale data on this API, so no Resale tab.
class StatusTabs extends StatelessWidget {
  const StatusTabs({super.key, required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?> onChanged;

  static const List<(String, int?)> _options = <(String, int?)>[
    ('All', null),
    ('Off-Plan', 2),
    ('Ready', 1),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final int selectedIndex = _options
        .indexWhere(((String, int?) o) => o.$2 == selected)
        .clamp(0, _options.length - 1);

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _options.length; i++) ...<Widget>[
            // Divider only between two unselected neighbours.
            if (i > 0)
              Container(
                width: 1,
                height: 20,
                color: i == selectedIndex || i - 1 == selectedIndex
                    ? Colors.transparent
                    : theme.dividerColor,
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(_options[i].$2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // Dark mode: a white pill (near-black vanished on the
                    // dark page), like the bottom bar's selected circle.
                    color: i == selectedIndex
                        ? (dark ? Colors.white : AppColors.primaryNavy)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Text(
                    _options[i].$1,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          i == selectedIndex ? FontWeight.w500 : FontWeight.w400,
                      color: i == selectedIndex
                          ? (dark ? AppColors.primaryNavy : Colors.white)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
