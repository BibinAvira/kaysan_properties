/// Centralized non-visual constants: copy, contact details, external links.
/// Keeping these out of widgets means UI code never hardcodes strings that
/// marketing/ops may need to change.
class AppConstants {
  AppConstants._();

  static const String appName = 'Kaysan Properties';
  static const String appTagline = 'Luxury Real Estate Investment in Dubai';

  // Contact
  static const String phoneNumber = '+971501990588';
  static const String phoneDisplay = '+971 50 199 0588';
  static const String whatsappNumber = '971501990588';
  static const String enquiryEmail = 'enquiry@kaysanproperties.ae';
  static const String careersEmail = 'careers@kaysanproperties.ae';
  static const String officeAddress =
      'Office No. 77-2700, Al Saqer Business Tower, Near Emirates Towers '
      'Metro Station, Dubai, UAE';

  // Socials
  static const String facebookUrl =
      'https://www.facebook.com/share/1CrvNvDpK1/?mibextid=wwXIfr';
  static const String instagramUrl =
      'https://www.instagram.com/kaysanproperties';
  static const String linkedinUrl =
      'https://www.linkedin.com/company/kaysan-properties/';
  static const String tiktokUrl =
      'https://www.tiktok.com/@kaysanproperties';
  static const String youtubeUrl =
      'https://youtube.com/@kaysanproperties';

  // Company stats (shown on Home > "Most Followed Real Estate Brand")
  static const String statSalesVolume = 'AED 3B+';
  static const String statProfessionals = '200+';
  static const String statExperience = '20+ Years';
  static const String statClients = '5,000+';

  static const int splashDurationMs = 1800;
  static const int apiTimeoutSeconds = 20;
  static const int apiRetryCount = 2;
}
