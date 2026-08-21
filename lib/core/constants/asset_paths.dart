/// Single source of truth for asset paths so a rename never becomes a
/// multi-file find-and-replace.
class AssetPaths {
  AssetPaths._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  static const String logo = '$_images/logo.png';
  static const String logoWhite = '$_images/logo_white.png';
  static const String placeholder = '$_images/placeholder.png';
  static const String onboardingBg = '$_images/onboarding_bg.png';
  static const String loginBg = '$_images/login.png';

  static const String icWhatsapp = '$_icons/whatsapp.svg';
  static const String icCall = '$_icons/call.svg';
  static const String icEmail = '$_icons/email.svg';
  static const String icShare = '$_icons/share.svg';
  static const String icNoInternet = '$_icons/no_internet.svg';
  static const String icEmptyState = '$_icons/empty_state.svg';
  static const String icError = '$_icons/error_state.svg';
}
