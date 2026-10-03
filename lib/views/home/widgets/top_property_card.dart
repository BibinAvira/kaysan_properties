import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project_model.dart';
import '../../../widgets/common_widgets.dart';

/// Home's "Top Property" card (client redesign) — used only there; every
/// other list keeps [PropertyCard]. Photo with a favorite button, then
/// title, developer, location and an arrow, then a Starting Price |
/// Handover row side by side rather than stacked on the left.
class TopPropertyCard extends StatelessWidget {
  const TopPropertyCard({
    super.key,
    required this.project,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final ProjectModel project;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  /// "Al Furjan, Dubai" — district plus region, minus Reelly's
  /// " Emirate" suffix ("Dubai Emirate").
  String get _location {
    final String district = project.district.name.display;
    final String region = project.city.name.display
        .replaceAll(RegExp(r'\s+Emirate$', caseSensitive: false), '')
        .trim();
    return <String>[district, region]
        .where((String s) => s.isNotEmpty)
        .toSet()
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime? handover = project.handoverDate;
    final String location = _location;
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  AppNetworkImage(url: project.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavoriteTap,
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFavorite
                                ? AppColors.error
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                            Text(project.title.display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text('by ${project.developer.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium),
                            if (location.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              // A text label rather than a pin icon — the
                              // icon sat visually off from the text around it.
                              Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    TextSpan(
                                        text: 'Location: ',
                                        style: theme.textTheme.labelSmall),
                                    TextSpan(
                                        text: location,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: theme.cardColor,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.chevron_right, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Price and handover as two equal, identically styled
                  // label-over-value columns in a tinted strip, so the two
                  // sides line up instead of one line vs two.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _Spec(
                            label: 'Starting Price',
                            value: project.lowPrice > 0
                                ? 'From ${Formatters.priceCompact(project.lowPrice)}'
                                : 'On Request',
                            valueColor: AppColors.gold,
                          ),
                        ),
                        if (project.propertyStatusCode == 1 ||
                            handover != null) ...<Widget>[
                          Container(
                              width: 1,
                              height: 30,
                              color: theme.dividerColor),
                          const SizedBox(width: 14),
                          Expanded(
                            // A finished building's completion date is in
                            // the past and reads like a stale listing date.
                            child: project.propertyStatusCode == 1
                                ? const _Spec(
                                    label: 'Status',
                                    value: 'Ready to move',
                                    valueColor: AppColors.success,
                                  )
                                : _Spec(
                                    label: 'Handover',
                                    value:
                                        DateFormat('MMM yyyy').format(handover!),
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One label-over-value detail in the card's bottom strip.
class _Spec extends StatelessWidget {
  const _Spec({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? theme.textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }
}
