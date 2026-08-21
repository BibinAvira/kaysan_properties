/// Centralized route paths/names for GoRouter. Views navigate via these
/// constants rather than hardcoded path strings.
class RouteNames {
  RouteNames._();

  static const String splash = '/splash';
  static const String home = '/';
  static const String listings = '/listings';
  static const String search = '/search';
  static const String propertyDetails = '/property/:id';
  static const String areas = '/areas';
  static const String areaDetails = '/areas/:id';
  static const String blogs = '/blogs';
  static const String blogDetails = '/blogs/:id';
  static const String favorites = '/favorites';
  static const String calculator = '/calculator';
  static const String contact = '/contact';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String terms = '/terms';
  static const String noInternet = '/no-internet';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';

  static String propertyDetailsPath(int id) => '/property/$id';
  static String areaDetailsPath(int id) => '/areas/$id';
  static String blogDetailsPath(int id) => '/blogs/$id';
}
