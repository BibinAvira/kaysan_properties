import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaysan_properties/core/utils/validators.dart';
import 'package:kaysan_properties/models/supporting_models.dart';
import 'package:kaysan_properties/providers/enquiry_provider.dart';

/// Shared "Register Interest" / Contact enquiry form. When [propertyId] and
/// [propertyTitle] are supplied it's scoped to a single project; otherwise
/// it's the general Contact Us form.
class EnquiryForm extends ConsumerStatefulWidget {
  const EnquiryForm({super.key, this.propertyId, this.propertyTitle});

  final int? propertyId;
  final String? propertyTitle;

  @override
  ConsumerState<EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends ConsumerState<EnquiryForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final EnquiryModel enquiry = EnquiryModel(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      message: _message.text.trim(),
      propertyId: widget.propertyId,
      propertyTitle: widget.propertyTitle,
    );
    await ref.read(enquiryControllerProvider.notifier).submit(enquiry);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool?>>(enquiryControllerProvider,
        (AsyncValue<bool?>? prev, AsyncValue<bool?> next) {
      next.whenOrNull(
        data: (bool? success) {
          if (success == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Thank you! Our team will contact you shortly.')),
            );
            _name.clear();
            _email.clear();
            _phone.clear();
            _message.clear();
            ref.read(enquiryControllerProvider.notifier).reset();
          }
        },
        error: (Object e, StackTrace st) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Something went wrong. Please try again.')),
          );
        },
      );
    });

    final bool isLoading = ref.watch(enquiryControllerProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.propertyTitle != null ? 'Register Interest' : 'Get in Touch',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: Validators.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email Address'),
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'Message (optional)'),
            maxLines: 3,
            validator: Validators.message,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Enquiry'),
            ),
          ),
        ],
      ),
    );
  }
}
