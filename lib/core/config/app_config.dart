/// Build/environment configuration.
///
/// [useMockData] is the single switch that swaps the mock repositories for
/// real HTTP-backed ones. Everything downstream (repositories, providers,
/// views) is written against the same interfaces, so flipping this flag —
/// and updating [apiBaseUrl] — is the only change needed to point at a
/// different backend.
class AppConfig {
  AppConfig._();

  /// Live: backed by the Reelly real-estate data API (read-only, key
  /// gated). Projects/Developers now come from this API — see
  /// [useMockData] below, which no longer applies to them.
  static const bool useMockData = false;

  /// Blogs, Testimonials, and Enquiry submission have **no equivalent
  /// endpoint** on Reelly either (it's a property-data-only API), so they
  /// stay on the local mock dataset regardless of [useMockData].
  /// This is intentionally a separate flag — flipping [useMockData] to
  /// `true` (e.g. for offline demos) does not accidentally imply these
  /// have a live counterpart, and flipping this to `false` requires
  /// actually wiring up real blog/testimonial/enquiry endpoints first.
  static const bool useMockContent = true;

  /// Live API root — the Reelly real-estate data API. Endpoints used:
  ///   GET {apiBaseUrl}/projects            — paginated project list
  ///   GET {apiBaseUrl}/projects/{id}       — single project detail
  ///   GET {apiBaseUrl}/projects/{id}/units — a project's individual units
  ///                                          (Enterprise-tier gated)
  ///   GET {apiBaseUrl}/developers          — full developer directory
  /// Every request must carry [propertyApiKey] in an `X-API-Key` header
  /// (see [ApiService]).
  static const String apiBaseUrl =
      'https://api-reelly.up.railway.app/api/v2/clients';

  /// Reelly API key, sent as `X-API-Key` on every [apiBaseUrl] request.
  ///
  /// NOTE: this key is baked into the compiled app, so anyone can extract
  /// it from the APK/IPA. Reelly's own guidance is to call this API from a
  /// backend server, never a browser/app client, specifically because a
  /// client-embedded key is exposed. Wiring it in directly like this is
  /// fine for local/dev testing, but it should go through your own backend
  /// before shipping to real users.
  static const String propertyApiKey =
      'eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRfbmFtZSI6IktheXNhbiBQcm9wZXJ0aWVzIn0.bdm6qzX5VAWJhcY2tNTRl6qty3-aK60StIAmq4S7-Tv10_fGYm_oTV9GEMdyrF2Dm3CXWudb7_wQ1qyGxFIvqw';

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

