import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// About Us screen — company positioning copy, mirroring the "Why Choose
/// Kaysan Properties" narrative from the website's About section.
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(AppConstants.appName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Your Partner in Dubai Real Estate Investment',
                    style: const TextStyle(color: AppColors.goldLight)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You’re looking to grow your wealth through Dubai’s booming property market — but navigating off-plan launches, developer credibility, and payment plans from afar isn’t easy. That’s where we come in.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'As a Dubai-based brokerage specializing in off-plan investment opportunities, we give you direct access to the UAE’s most sought-after developments, backed by strong relationships with leading developers and deep, on-the-ground market knowledge. Whether you’re investing from Dubai or overseas, you get a team that understands your goals and guides you through every stage — from your first consultation to final handover.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'We believe you deserve transparent advice, not sales pitches. That’s why we combine market expertise with a client-first approach, so you can make confident, well-informed investment decisions at every step.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text('Our Mission', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'To be your most trusted partner for property investment in Dubai — giving you honest guidance, curated opportunities, and long-term value on every investment you make.',
            style: textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
