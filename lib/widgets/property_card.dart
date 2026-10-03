import 'dart:ui' show ImageFilter;

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
/// the bottom carries the name, "developer · area", and a frosted glass
/// strip with the starting price and the handover month (or "Ready to
/// move" for finished buildings).
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
    final bool isReady = project.propertyStatusCode == 1;
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
                    ..._priceAndHandover(isReady, handover),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  /// A frosted glass strip under the name: the starting price, then the
  /// handover month (off-plan) or "Ready to move" (a finished building,
  /// whose past completion date read like a stale listing date).
  List<Widget> _priceAndHandover(bool isReady, DateTime? handover) {
    final String price = project.lowPrice > 0
        ? Formatters.priceCompact(project.lowPrice)
        : 'On Request';
    final bool showWhen = isReady || handover != null;
    return <Widget>[
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Column(
              children: <Widget>[
                _GlassRow(
                    label: 'Starting',
                    value: price,
                    valueColor: AppColors.goldLight),
                if (showWhen) ...<Widget>[
                  const SizedBox(height: 3),
                  _GlassRow(
                    label: isReady ? 'Status' : 'Handover',
                    value: isReady
                        ? 'Ready to move'
                        : DateFormat('MMM yyyy').format(handover!),
                    valueColor: isReady ? _readyOnDark : Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  /// [AppColors.success] lifted for legibility on the dark photo fade.
  static const Color _readyOnDark = Color(0xFF7FE3AE);
}

/// One label/value row in the card's glass strip.
class _GlassRow extends StatelessWidget {
  const _GlassRow(
      {required this.label, required this.value, required this.valueColor});
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label,
            style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
        const Spacer(),
        Text(value,
            maxLines: 1,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
      ],
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
