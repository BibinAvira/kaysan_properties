import 'package:share_plus/share_plus.dart';
import 'package:share_plus/share_plus.dart' as SharePlus;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

/// Wraps `url_launcher` / `share_plus` so views never touch platform APIs
/// directly. Every call site handles the bool result and swallows failures
/// into a no-op rather than throwing during a tap gesture.
class LauncherUtils {
  LauncherUtils._();

  static Future<bool> call(String phoneNumber) {
    return _launch(Uri(scheme: 'tel', path: phoneNumber));
  }

  static Future<bool> email(
    String address, {
    String subject = '',
    String body = '',
  }) {
    return _launch(Uri(
      scheme: 'mailto',
      path: address,
      query: _encodeQueryParameters(<String, String>{
        if (subject.isNotEmpty) 'subject': subject,
        if (body.isNotEmpty) 'body': body,
      }),
    ));
  }

  static Future<bool> whatsapp(String message) {
    final Uri uri = Uri.parse(
      'https://wa.me/${AppConstants.whatsappNumber}'
      '?text=${Uri.encodeComponent(message)}',
    );
    return _launch(uri);
  }

  static Future<bool> openMap(double lat, double lng, {String label = ''}) {
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    return _launch(uri);
  }

  static Future<bool> openUrl(String url) => _launch(Uri.parse(url));

  static Future<void> shareProperty({
    required String title,
    required String url,
  }) async {
    await SharePlus.Share(
        //  ShareParams(text: '$title — via Kaysan Properties\n$url'),
        );
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static String? _encodeQueryParameters(Map<String, String> params) {
    if (params.isEmpty) return null;
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
