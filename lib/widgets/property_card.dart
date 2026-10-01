import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/project_model.dart';
import 'common_widgets.dart';

/// The single card representation of a [ProjectModel], reused across
/// Listings, Favorites, developer and area pages so the visual language
/// stays consistent everywhere a property is listed.
///
/// "Photo overlay" design: the photo fills the whole card, a dark fade at
/// the bottom carries the name, "developer · area", and two pills —
/// handover date and the gold price.
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

  /// Soft drop shadow so the white title/subtitle stay crisp over bright
  /// patches of the cover photo that the fade doesn't fully darken.
  static const List<Shadow> _textShadow = <Shadow>[
    Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime? handover = project.handoverDate;
    final String subtitle = <String>[
      project.developer.name,
      project.district.name.display,
    ].where((String s) => s.isNotEmpty).join(' · ');

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AppNetworkImage(url: project.cover),
              // Dark fade over the lower 70% so white text stays legible
              // on any photo.
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        Color(0xF00C0D12),
                        Color(0x000C0D12),
                      ],
                      stops: <double>[0, 0.7],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _FavoriteButton(
                    isFavorite: isFavorite, onTap: onFavoriteTap),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      project.title.display,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        shadows: _textShadow,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          shadows: _textShadow,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // One row on every card (a Wrap put the second pill on
                    // its own line on narrow cards, so cards didn't match).
                    // Price first; either pill shortens with "…" if needed.
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: _Pill(
                            text: project.lowPrice > 0
                                ? Formatters.priceCompact(project.lowPrice)
                                : 'On Request',
                            background: AppColors.goldLight,
                            foreground: const Color(0xFF1C1400),
                            bold: true,
                          ),
                        ),
                        if (handover != null) ...<Widget>[
                          const SizedBox(width: 5),
                          Flexible(
                            child: _Pill(
                              text: DateFormat('MMM yyyy').format(handover),
                              background: Colors.black.withValues(alpha: 0.45),
                              foreground: Colors.white,
                            ),
                          ),
                        ],
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

/// Small rounded label on the photo (handover date, price).
class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
    this.bold = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 10.5,
          height: 1.25,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// White round heart in a 44px tap area in the photo's top-right corner.
class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});
  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color:
                    isFavorite ? AppColors.error : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
