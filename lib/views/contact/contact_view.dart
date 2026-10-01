import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../widgets/contact_actions_bar.dart';

/// Contact Us screen — branded header, tappable office/phone/email tiles,
/// and the sticky direct contact actions.
class ContactView extends ConsumerWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: <Widget>[
          const _ContactHeader(),
          const SizedBox(height: 24),
          const _SectionLabel('Get in touch'),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.location_on_outlined,
            label: 'Visit our office',
            value: AppConstants.officeAddress,
            trailing: Icons.directions_outlined,
            onTap: () => LauncherUtils.openUrl(
              'https://www.google.com/maps/search/?api=1&query='
              '${Uri.encodeComponent(AppConstants.officeAddress)}',
            ),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.call_outlined,
            label: 'Call us',
            value: AppConstants.phoneDisplay,
            onTap: () async {
              if (await requireAuth(context, ref)) {
                LauncherUtils.call(AppConstants.phoneNumber);
              }
            },
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.email_outlined,
            label: 'Email us',
            value: AppConstants.enquiryEmail,
            onTap: () async {
              if (await requireAuth(context, ref)) {
                LauncherUtils.email(AppConstants.enquiryEmail);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const ContactActionsBar(
        whatsappMessage:
            'Hello! I\'d like to know more about your Dubai properties.',
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  const _ContactHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.primaryNavyLight, AppColors.primaryNavy],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent,
                color: AppColors.goldLight, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Let\'s talk property',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontFamily: 'DMSerifDisplay',
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our Dubai team is here to help you find the right off-plan '
            'investment. Reach out any way you like.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(color: secondary)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(trailing, size: 22, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}
