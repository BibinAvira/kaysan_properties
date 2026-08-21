import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/contact_actions_bar.dart';
import '../property_details/widgets/enquiry_form.dart';

/// Contact Us screen — office info, direct contact actions, and the
/// general enquiry form (unscoped to any specific property).
class ContactView extends StatelessWidget {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.scaffoldLight, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.location_on_outlined, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Expanded(child: Text(AppConstants.officeAddress, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(Icons.call_outlined, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(AppConstants.phoneDisplay, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    const Icon(Icons.email_outlined, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(AppConstants.enquiryEmail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const EnquiryForm(),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: const ContactActionsBar(),
    );
  }
}
