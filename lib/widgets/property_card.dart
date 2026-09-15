import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/project_model.dart';
import 'common_widgets.dart';
import 'glass/liquid_glass.dart';

/// The single card representation of a [ProjectModel], reused across Home,
/// Listings, Favorites and Area Details so the visual language stays
/// consistent everywhere a property is listed.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteTap,
    this.width,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Image now flexes to fill whatever space is left after the
              // text block below takes what it needs — this is what
              // eliminates the bottom overflow, since the old AspectRatio
              // sized the image purely off card width, independent of the
              // grid cell's actual height.
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    AppNetworkImage(url: project.cover),
                    if (project.handoverDate != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _Badge(
                          text: 'Handover: ${Formatters.handoverLabel(project.handoverDate!)}',
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _FavoriteButton(
                          isFavorite: isFavorite, onTap: onFavoriteTap),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      project.title.display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${project.developer.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: <InlineSpan>[
                          const TextSpan(text: 'Starting Price  '),
                          TextSpan(
                            text: project.lowPrice > 0
                                ? Formatters.priceCompact(project.lowPrice)
                                : 'On Request',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(Icons.location_on_outlined,
                            size: 14, color: theme.textTheme.bodyMedium?.color),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.district.name.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        if (project.subunitCount.display.isNotEmpty)
                          Flexible(
                            child: Text(
                              project.subunitCount.display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      borderRadius: 9,
      blur: 20,
      tintOpacity: 0.14,
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCircle(
      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
      iconColor: isFavorite ? AppColors.error : Colors.white,
      size: 32,
      iconSize: 17,
      blur: 20,
      tintOpacity: 0.18,
      onTap: onTap,
    );
  }
}
