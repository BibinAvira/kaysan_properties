import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/supporting_models.dart';
import 'di_providers.dart';

/// Tracks the async lifecycle of submitting a Contact / Register-Interest
/// form: idle -> loading -> data(true)/error. Views reset it back to idle
/// (via `ref.invalidate`) whenever the form sheet is reopened.
class EnquiryController extends AsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  Future<void> submit(EnquiryModel enquiry) async {
    state = const AsyncValue<bool?>.loading();
    state = await AsyncValue.guard(() => ref.read(enquiryRepositoryProvider).submitEnquiry(enquiry));
  }

  void reset() => state = const AsyncValue<bool?>.data(null);
}

final AsyncNotifierProvider<EnquiryController, bool?> enquiryControllerProvider =
    AsyncNotifierProvider<EnquiryController, bool?>(EnquiryController.new);
