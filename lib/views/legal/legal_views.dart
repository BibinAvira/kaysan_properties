import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Privacy Policy screen. Copy is a standard real-estate-brokerage privacy
/// notice placeholder — replace with Kaysan Properties' actual legal text
/// before shipping to production.
class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text('Last updated: July 2026', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          _Section(
            title: 'Information We Collect',
            body: 'We collect the information you provide directly to us, such as your name, '
                'email address, and phone number when you submit an enquiry or register '
                'interest in a property, as well as usage data collected automatically '
                'through your use of the app.',
          ),
          _Section(
            title: 'How We Use Your Information',
            body: 'We use the information we collect to respond to your enquiries, provide '
                'you with property recommendations, improve our services, and communicate '
                'with you about listings that may be of interest.',
          ),
          _Section(
            title: 'Sharing of Information',
            body: 'We do not sell your personal information. We may share limited details with '
                'developers or partner agents solely to process a specific enquiry you have '
                'submitted, and only with your consent.',
          ),
          _Section(
            title: 'Your Rights',
            body: 'You may request access to, correction of, or deletion of your personal data '
                'at any time by contacting us at ${AppConstants.enquiryEmail}.',
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
