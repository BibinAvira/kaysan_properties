import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Privacy Policy screen.
///
/// NOTE: this copy describes what the app actually does (account fields
/// collected, no location/tracking, self-serve in-app deletion) but it is
/// NOT a substitute for legal review — have Kaysan Properties' counsel sign
/// off on this text before the next App Store submission. Apple reads this
/// screen during review and rejects policies that don't match real app
/// behavior (Guideline 5.1.1/5.1.2), so keep it in sync with the code —
/// e.g. if a tracking/analytics SDK or new permission is ever added, this
/// text needs to say so.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Last updated: August 2026', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          _Section(
            title: 'Information We Collect',
            body: 'Browsing properties, areas, and blog content does not require an account and '
                'we do not collect any personal information for it. If you create an account, '
                'we collect your username, password, and any of full name, email address, or '
                'phone number you choose to add to your profile. If you submit a property '
                'enquiry or contact us, we collect the name, email, phone number, and message '
                'you provide. We do not access your device location, contacts, or photos.',
          ),
          _Section(
            title: 'How We Use Your Information',
            body: 'We use this information to operate your account, respond to enquiries, show '
                'you your saved favorites, and communicate with you about listings you\'ve '
                'asked about. We do not use your information for advertising, and we do not '
                'use analytics or tracking SDKs that identify you individually.',
          ),
          _Section(
            title: 'Sharing of Information',
            body: 'We do not sell your personal information. We may share the details of a '
                'specific enquiry with the relevant developer or partner agent solely to '
                'respond to that enquiry.',
          ),
          _Section(
            title: 'Data Retention',
            body: 'We retain account and enquiry data for as long as your account is active or '
                'as needed to respond to your enquiries, and delete it when you delete your '
                'account or request removal.',
          ),
          _Section(
            title: 'Your Rights — Deleting Your Account',
            body: 'You can permanently delete your account and its associated data at any time '
                'from the app: go to More > your account > Delete Account, confirm, and it '
                'takes effect immediately — no need to contact support. You can also request '
                'access to, correction of, or deletion of your data by emailing '
                '${AppConstants.enquiryEmail}.',
          ),
          _Section(
            title: 'Contact Us',
            body: 'If you have questions about this Privacy Policy, please reach out to us at '
                '${AppConstants.enquiryEmail} or ${AppConstants.phoneDisplay}.',
          ),
        ],
      ),
    );
  }
}

/// Terms & Conditions screen.
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Last updated: July 2026', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          const _Section(
            title: 'Acceptance of Terms',
            body: 'By using the Kaysan Properties app, you agree to be bound by these Terms & '
                'Conditions. If you do not agree, please discontinue use of the app.',
          ),
          const _Section(
            title: 'Property Listings',
            body: 'All property information, pricing, and availability displayed in this app '
                'are subject to change without notice and do not constitute a binding offer. '
                'Prices and unit availability should be confirmed directly with our team.',
          ),
          const _Section(
            title: 'No Investment Advice',
            body: 'Content provided in this app, including blog articles, is for general '
                'informational purposes only and does not constitute financial, legal, or '
                'investment advice.',
          ),
          const _Section(
            title: 'Limitation of Liability',
            body: 'Kaysan Properties shall not be liable for any indirect, incidental, or '
                'consequential damages arising from your use of this app or reliance on any '
                'information contained within it.',
          ),
          const _Section(
            title: 'Governing Law',
            body: 'These Terms are governed by the laws of the Emirate of Dubai and the '
                'applicable federal laws of the United Arab Emirates.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
