import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project_model.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/glass/liquid_glass.dart';

/// Swipeable image gallery for a project's photos. Tapping opens a
/// full-screen pinch-to-zoom [PhotoViewGallery].
class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key, required this.images});
  final List<String> images;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        widget.images.isEmpty ? <String>[''] : widget.images;
    final bool hasMultiple = images.length > 1;

    return SizedBox(
      height: 280,
      child: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (int i) => setState(() => _index = i),
            itemBuilder: (BuildContext context, int i) {
              return GestureDetector(
                onTap: () => _openFullScreen(context, images, i),
                child: AppNetworkImage(url: images[i]),
              );
            },
          ),
          if (hasMultiple) ...<Widget>[
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrowButton(
                  icon: Icons.chevron_left,
                  onTap: _index > 0
                      ? () => _controller.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut)
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _GalleryArrowButton(
                  icon: Icons.chevron_right,
                  onTap: _index < images.length - 1
                      ? () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut)
                      : null,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  images.length,
                  (int i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
          Positioned(
            bottom: 12,
            right: 12,
            child: LiquidGlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              borderRadius: 12,
              blur: 20,
              tintOpacity: 0.16,
              child: Text('${_index + 1}/${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(
      BuildContext context, List<String> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white)),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: initialIndex),
            builder: (BuildContext context, int i) =>
                PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Prev/next chevron overlay for [ImageGallery] — dimmed and non-tappable
/// (rather than hidden) at either end, so the control doesn't jump around
/// as the user pages through.
class _GalleryArrowButton extends StatelessWidget {
  const _GalleryArrowButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1,
      child: LiquidGlassCircle(
        icon: icon,
        iconColor: Colors.white,
        size: 32,
        iconSize: 20,
        blur: 20,
        tintOpacity: 0.18,
        onTap: onTap ?? () {},
      ),
    );
  }
}

/// Facilities grid (e.g. "Swimming Pool", "Gym", "Concierge Service"). The
/// API only gives `{id, name}` — no icon hint — so an icon is resolved by
/// keyword-matching the (English) facility name, falling back to a
/// generic star for anything unrecognized.
class FacilitiesGrid extends StatelessWidget {
  const FacilitiesGrid({super.key, required this.facilities});
  final List<FacilityModel> facilities;

  static IconData _iconFor(String name) {
    final String n = name.toLowerCase();
    if (n.contains('pool')) return Icons.pool;
    if (n.contains('gym') || n.contains('fitness')) return Icons.fitness_center;
    if (n.contains('spa') ||
        n.contains('sauna') ||
        n.contains('steam') ||
        n.contains('jacuzzi')) return Icons.spa;
    if (n.contains('security') || n.contains('guard')) return Icons.security;
    if (n.contains('concierge')) return Icons.support_agent;
    if (n.contains('restaurant') || n.contains('cafe')) return Icons.restaurant;
    if (n.contains('play') || n.contains('kid') || n.contains('child'))
      return Icons.child_care;
    if (n.contains('parking')) return Icons.local_parking;
    if (n.contains('tennis')) return Icons.sports_tennis;
    if (n.contains('park') || n.contains('garden')) return Icons.park;
    if (n.contains('beach')) return Icons.beach_access;
    if (n.contains('marina') || n.contains('yacht')) return Icons.sailing;
    if (n.contains('cinema') || n.contains('theatre') || n.contains('theater'))
      return Icons.theaters;
    if (n.contains('bbq') || n.contains('barbecue')) return Icons.outdoor_grill;
    if (n.contains('lounge')) return Icons.weekend;
    if (n.contains('retail') || n.contains('shop')) return Icons.storefront;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('No facilities listed for this project yet.'),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: facilities.length,
      itemBuilder: (BuildContext context, int index) {
        final FacilityModel facility = facilities[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(_iconFor(facility.name.display), color: AppColors.gold),
              const SizedBox(height: 6),
              Text(
                facility.name.display,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Unit Details" tab: floor-plan summary cards (from `grouped_apartments`,
/// currently always empty for this API — see [GroupedApartmentModel]'s doc
/// comment) plus the individually listed units fetched from the project's
/// `/units/` endpoint, each showing its type, area, status and price.
class FloorPlansTab extends StatelessWidget {
  const FloorPlansTab(
      {super.key,
      required this.groupedApartments,
      required this.propertyUnits});
  final List<GroupedApartmentModel> groupedApartments;
  final List<PropertyUnitModel> propertyUnits;

  @override
  Widget build(BuildContext context) {
    if (groupedApartments.isEmpty && propertyUnits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Floor plans will be shared upon request.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (groupedApartments.isNotEmpty) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Unit Types',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...groupedApartments.map((GroupedApartmentModel plan) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.aspect_ratio,
                            color: AppColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(plan.title,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(
                                'From ${plan.minArea.toStringAsFixed(0)} sq.ft',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Text('From ${Formatters.priceCompact(plan.minPrice)}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              )),
        ],
        if (propertyUnits.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Available Units (${propertyUnits.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...propertyUnits.take(20).map((PropertyUnitModel unit) => ListTile(
                dense: true,
                leading: const Icon(Icons.door_front_door_outlined,
                    color: AppColors.gold),
                title: Text(unit.bedroomLabel.isNotEmpty
                    ? 'Unit ${unit.aptNo} · ${unit.bedroomLabel}'
                    : 'Unit ${unit.aptNo}'),
                subtitle: Row(
                  children: <Widget>[
                    if (unit.area != null)
                      Text('${unit.area!.toStringAsFixed(0)} sq.ft'),
                    if (unit.area != null && _unitStatusLabel(unit.status) != null)
                      const Text('  ·  '),
                    if (_unitStatusLabel(unit.status) case final String label)
                      Text(label,
                          style: TextStyle(
                              color: _unitStatusColor(unit.status),
                              fontWeight: FontWeight.w600)),
                  ],
                ),
                trailing: unit.price != null
                    ? Text(Formatters.priceCompact(unit.price!))
                    : null,
              )),
          if (propertyUnits.length > 20)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '+ ${propertyUnits.length - 20} more units available — contact us for the full list.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ],
    );
  }

  /// Display label for a unit's `status` (`available`/`reserved`/`sold`/
  /// `unknown` per the API) — null for "unknown" or empty, since that
  /// tells the user nothing worth showing.
  static String? _unitStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'sold':
        return 'Sold';
      default:
        return null;
    }
  }

  static Color _unitStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.success;
      case 'reserved':
        return AppColors.warning;
      case 'sold':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }
}

/// Payment plan card (e.g. "60/40") with its milestone breakdown.
class PaymentPlanCard extends StatelessWidget {
  const PaymentPlanCard({super.key, required this.plans});
  final List<PaymentPlanModel> plans;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plans
          .map((PaymentPlanModel plan) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          plan.name.display.isNotEmpty
                              ? plan.name.display
                              : 'Payment Plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (plan.description.display.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(plan.description.display,
                                style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...plan.values.map((PaymentPlanValueModel v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(
                                  child: Text(v.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium)),
                              Text(v.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 14)),
                            ],
                          ),
                        )),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

/// Embedded Google Map centered on the project's coordinates. Falls back
/// to a plain message if the API's `address` field couldn't be parsed
/// into a lat/lng pair.
///
/// Requires a Maps API key configured natively (see README).
// class LocationMap extends StatelessWidget {
//   const LocationMap(
//       {super.key,
//       required this.latitude,
//       required this.longitude,
//       required this.label});
//   final double? latitude;
//   final double? longitude;
//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     if (latitude == null || longitude == null) {
//       return Container(
//         height: 120,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//             color: AppColors.scaffoldLight,
//             borderRadius: BorderRadius.circular(16)),
//         child: const Text('Location unavailable for this project.'),
//       );
//     }
//     final LatLng position = LatLng(latitude!, longitude!);
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: SizedBox(
//         height: 180,
//         child: GoogleMap(
//           initialCameraPosition: CameraPosition(target: position, zoom: 13),
//           markers: <Marker>{
//             Marker(
//                 markerId: const MarkerId('project'),
//                 position: position,
//                 infoWindow: InfoWindow(title: label))
//           },
//           zoomControlsEnabled: false,
//           myLocationButtonEnabled: false,
//           // liteModeOnAndroid: true,
//         ),
//       ),
//     );
//   }
// }
