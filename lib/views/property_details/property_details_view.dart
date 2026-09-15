import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/html_utils.dart';
import '../../core/utils/launcher_utils.dart';
import '../../models/project_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/contact_actions_bar.dart';
import '../../widgets/glass/liquid_glass.dart';
import 'widgets/property_details_widgets.dart';

/// Property Details screen — the richest screen in the app: gallery,
/// key facts, tabs for Overview/Floor Plans/Location, facilities grid,
/// payment plan, capped with a sticky contact actions bar.
class PropertyDetailsView extends ConsumerWidget {
  const PropertyDetailsView({super.key, required this.projectId});
  final int projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectModel> project =
        ref.watch(projectDetailsProvider(projectId));

    return Scaffold(
      body: project.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => EmptyStateView(
          icon: Icons.error_outline,
          title: 'Property not found',
          message:
              'We could not load this property. Please go back and try again.',
          actionLabel: 'Retry',
          onActionTap: () => ref.invalidate(projectDetailsProvider(projectId)),
        ),
        data: (ProjectModel data) => _DetailsContent(project: data),
      ),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);
    final bool isFavorite = favorites.maybeWhen(
        data: (Set<int> ids) => ids.contains(project.id), orElse: () => false);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ImageGallery(images: project.galleryImages),
                      Positioned(
                        top: 8,
                        left: 12,
                        child: SafeArea(
                          bottom: false,
                          child: _GalleryRoundButton(
                            icon: Icons.arrow_back,
                            onTap: () => context.pop(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 12,
                        child: SafeArea(
                          bottom: false,
                          child: _GalleryRoundButton(
                            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                            iconColor: isFavorite ? AppColors.gold : Colors.white,
                            onTap: () async {
                              if (await requireAuth(context, ref)) {
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(project.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const TabBar(
                      labelColor: AppColors.primaryNavy,
                      unselectedLabelColor: AppColors.textSecondaryLight,
                      indicatorColor: AppColors.gold,
                      indicatorWeight: 3,
                      tabs: <Widget>[
                        Tab(text: 'Overview'),
                        Tab(text: 'Unit Details'),
                        Tab(text: 'Location'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: <Widget>[
              _OverviewTab(project: project),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: FloorPlansTab(
                  groupedApartments: project.groupedApartments,
                  propertyUnits: project.propertyUnits,
                ),
              ),
              _LocationTab(project: project),
            ],
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _PriceEnquireBar(project: project),
            ContactActionsBar(
              shareTitle: project.title.display,
              shareUrl: project.addressText.isNotEmpty
                  ? project.addressText
                  : 'https://www.x-opperp.com/property/${project.id}',
              whatsappMessage: 'Hi, I\'m interested in ${project.title.display}.',
            ),
          ],
        ),
      ),
    );
  }
}

/// Price + primary CTA row shown above [ContactActionsBar], mirroring the
/// design's price/"Book Now" bar. There's no in-app booking flow backing
/// this API yet, so the CTA opens WhatsApp pre-filled for this property —
/// the same channel the rest of the app already uses for enquiries.
class _PriceEnquireBar extends ConsumerWidget {
  const _PriceEnquireBar({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      color: Theme.of(context).cardColor,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Starting Price', style: Theme.of(context).textTheme.labelSmall),
                Text(
                  project.lowPrice > 0
                      ? Formatters.priceCompact(project.lowPrice)
                      : 'On Request',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: AppColors.gold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            onPressed: () async {
              if (await requireAuth(context, ref)) {
                LauncherUtils.whatsapp(
                  'Hi, I\'m interested in ${project.title.display}.',
                );
              }
            },
            child: const Text('Enquire Now'),
          ),
        ],
      ),
    );
  }
}

/// Floating circular icon button used for the back/favorite controls over
/// the gallery, matching the Figma design's overlay buttons — now a true
/// frosted liquid-glass circle rather than an opaque white disc.
class _GalleryRoundButton extends StatelessWidget {
  const _GalleryRoundButton({required this.icon, required this.onTap, this.iconColor});
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCircle(
      icon: icon,
      iconColor: iconColor ?? Colors.white,
      size: 40,
      iconSize: 20,
      onTap: onTap,
    );
  }
}

class _LocationTab extends StatelessWidget {
  const _LocationTab({required this.project});
  final ProjectModel project;

  Uri _googleMapsUri() {
    final bool hasCoords = project.latitude != 0 && project.longitude != 0;
    if (hasCoords) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${project.latitude},${project.longitude}',
      );
    }
    final String query = Uri.encodeComponent(
      project.addressText.isNotEmpty
          ? project.addressText
          : '${project.title.display}, ${project.district.name.display}, ${project.city.name.display}',
    );
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  }

  Future<void> _openInMaps(BuildContext context) async {
    final Uri uri = _googleMapsUri();
    final bool launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${project.district.name.display}, ${project.city.name.display}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (project.addressText.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            // Text(project.addressText,
            //     style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openInMaps(context),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final String descriptionText = project.description != null
        ? HtmlUtils.stripTags(project.description!.display)
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(project.title.display,
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'by ${project.developer.name} · ${project.district.name.display}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _KeyFactsRow(project: project),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(
                      RouteNames.calculator,
                      extra: project.lowPrice > 0 ? project.lowPrice : null,
                    ),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Mortgage & ROI Calculator'),
                  ),
                ),
                const SizedBox(height: 20),
                Text('About this project',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  descriptionText.isNotEmpty
                      ? descriptionText
                      : 'No description provided for this project yet.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Payment Plan',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: project.paymentPlans.isNotEmpty
                ? PaymentPlanCard(plans: project.paymentPlans)
                : Text('Payment plan details are not available for this project yet.',
                    style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Facilities',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 12),
          FacilitiesGrid(facilities: project.facilities),
        ],
      ),
    );
  }
}

/// Key facts grid. Always shows Starting Price and Status; everything else
/// (Handover, Property Type, Area, Unit Type, Units) only appears when the
/// API actually returned that data for this property, rather than a fixed
/// set of slots padded out with placeholder dashes.
class _KeyFactsRow extends StatelessWidget {
  const _KeyFactsRow({required this.project});
  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final DateTime? handover = project.handoverDate;

    final List<(String, String)> facts = <(String, String)>[
      (
        'Starting Price',
        project.lowPrice > 0 ? Formatters.priceCompact(project.lowPrice) : 'On Request',
      ),
      ('Status', project.salesStatusDisplay),
      // Hidden entirely (rather than falling back to a status word) when
      // there's no real handover date — see ProjectModel._parseDeliveryDate
      // for why a date isn't always available even for an Off-Plan project.
      if (handover != null) ('Handover', Formatters.handoverLabel(handover)),
      if (project.propertyType.isNotEmpty) ('Property Type', project.propertyType),
      if (project.minArea > 0) ('Area', 'From ${project.minArea.toStringAsFixed(0)} sq.ft'),
      if (project.subunitCount.display.isNotEmpty) ('Unit Type', project.subunitCount.display),
      if (project.residentialUnits != null) ('Units', '${project.residentialUnits}'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(14)),
      child: Wrap(
        spacing: 20,
        runSpacing: 14,
        children: facts.map(((String, String) f) => _fact(context, f.$1, f.$2)).toList(),
      ),
    );
  }

  Widget _fact(BuildContext context, String label, String value) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.gold)),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
