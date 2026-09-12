/// Build/environment configuration.
///
/// [useMockData] is the single switch that swaps the mock repositories for
/// real HTTP-backed ones. Everything downstream (repositories, providers,
/// views) is written against the same interfaces, so flipping this flag —
/// and updating [apiBaseUrl] — is the only change needed to point at a
/// different backend.
class AppConfig {
  AppConfig._();

  /// Live: backed by the X-OPP Partner Property API (read-only, key +
  /// IP-whitelist gated). Projects/Areas/Developers now come from this
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

  /// Live API root — the X-OPP Partner Property API. Endpoints used:
  ///   GET {apiBaseUrl}/properties/            — paginated property list
  ///   GET {apiBaseUrl}/properties/{id}/       — single property detail
  ///   GET {apiBaseUrl}/properties/{id}/units/ — a project's individual units
  /// Every request must carry [xoppApiKey] in an `X-API-Key` header (see
  /// [ApiService]); the partner's server IP must also be whitelisted with
  /// the X-OPP administrator, or requests fail with 401 regardless of key.
  static const String apiBaseUrl = 'https://www.x-opperp.com/api/v1/partner';

  /// X-OPP partner API key, sent as `X-API-Key` on every [apiBaseUrl]
  /// request. Shown only once at creation by the X-OPP administrator — if
  /// it needs rotating, this is the only place to update it.
  ///
  /// NOTE: this key is baked into the compiled app, so anyone can extract
  /// it from the APK/IPA. The X-OPP docs say to call this API from a
  /// backend server, never a browser/app client, specifically because a
  /// client-embedded key is exposed and because requests are IP-whitelisted
  /// (a phone's IP isn't the whitelisted server IP). Wiring it in directly
  /// like this is fine for local/dev testing in the emulator, but it should
  /// go through your own backend before shipping to real users.
  static const String xoppApiKey = 'xopp_LqYcvEGLbzmmJGfzo6vGaaPdSWYw6cDf5OVuBEpH8qk';

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

