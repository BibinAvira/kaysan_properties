/// Build/environment configuration.
///
/// [useMockData] is the single switch that swaps the mock repositories for
/// real HTTP-backed ones. Everything downstream (repositories, providers,
/// views) is written against the same interfaces, so flipping this flag —
/// and updating [apiBaseUrl] — is the only change needed to point at a
/// different backend.
class AppConfig {
  AppConfig._();

  /// Live: backed by the x-opp microservice (Estaty-style off-plan
  /// properties aggregator). Projects/Areas/Developers now come from this
  /// API — see [useMockData] below, which no longer applies to them.
  static const bool useMockData = false;

  /// Blogs, Testimonials, and Enquiry submission have **no equivalent
  /// endpoint** on the x-opp microservice (it's a properties-only API), so
  /// they stay on the local mock dataset regardless of [useMockData].
  /// This is intentionally a separate flag — flipping [useMockData] to
  /// `true` (e.g. for offline demos) does not accidentally imply these
  /// have a live counterpart, and flipping this to `false` requires
  /// actually wiring up real blog/testimonial/enquiry endpoints first.
  static const bool useMockContent = true;

  /// Live API root. Endpoints used:
  ///   GET {apiBaseUrl}/properties/         — paginated property list
  ///   GET {apiBaseUrl}/property/{id}/      — single property detail
  static const String apiBaseUrl = 'https://microservice.x-opp.com/api';

  /// Auth microservice root — separate backend from [apiBaseUrl] above, so
  /// it gets its own [ApiService]-style client (see `AuthService`) rather
  /// than being bolted onto the properties client.
  ///   POST {authBaseUrl}/register/       — create account
  ///   POST {authBaseUrl}/login/          — obtain access + refresh tokens
  ///   POST {authBaseUrl}/token/refresh/  — exchange refresh for new access
  ///   GET/PATCH/PUT {authBaseUrl}/profile/ — logged-in user's profile
  static const String authBaseUrl = 'https://api.kaysanproperties.ae/api/auth';

  /// Google Maps API key — required for the embedded project-location maps.
  /// Supply via --dart-define=GOOGLE_MAPS_API_KEY=xxxx at build time and
  /// wire it into android/ios native config (see README).
  static const String googleMapsApiKeyPlaceholder =
      'PROVIDE_YOUR_GOOGLE_MAPS_API_KEY';

  static const bool enableLogging = bool.fromEnvironment(
    'dart.vm.product',
    defaultValue: false,
  )
      ? false
      : true;
}

