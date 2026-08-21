import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/launcher_utils.dart';

/// Sticky bottom bar offering Call / WhatsApp / Email / Share actions —
/// the standard contact affordance repeated across Property Details and
/// the Contact screen.
class ContactActionsBar extends StatelessWidget {
  const ContactActionsBar({
    super.key,
    this.shareTitle,
    this.shareUrl,
    this.whatsappMessage,
  });

  final String? shareTitle;
  final String? shareUrl;
  final String? whatsappMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: <Widget>[
            _ActionIconButton(
              icon: Icons.call,
              color: AppColors.primaryNavy,
              label: 'Call',
              onTap: () => LauncherUtils.call(AppConstants.phoneNumber),
            ),
            const SizedBox(width: 10),
            _ActionIconButton(
              icon: Icons.chat,
              color: AppColors.whatsapp,
              label: 'WhatsApp',
              onTap: () => LauncherUtils.whatsapp(
                whatsappMessage ??
                    'Hello! I came across $shareTitle on your website and it caught my interest. Could you please share more details?',
              ),
            ),
            const SizedBox(width: 10),
            _ActionIconButton(
              icon: Icons.email_outlined,
              color: AppColors.gold,
              label: 'Email',
              onTap: () => LauncherUtils.email(
                AppConstants.enquiryEmail,
                subject:
                    shareTitle != null ? 'Enquiry: $shareTitle' : 'Enquiry',
              ),
            ),
            // if (shareTitle != null && shareUrl != null) ...<Widget>[
            //   const SizedBox(width: 10),
            //   _ActionIconButton(
            //     icon: Icons.share_outlined,
            //     color: AppColors.textSecondaryLight,
            //     label: 'Share',
            //     onTap: () => LauncherUtils.shareProperty(title: shareTitle!, url: shareUrl!),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
