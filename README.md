# Kaysan Properties — Flutter App

A native Flutter reimplementation of [kaysanproperties.ae](https://www.kaysanproperties.ae/), a Dubai
off-plan real-estate brokerage site. Built with MVC-style layering, Riverpod, Dio, and GoRouter.

## ⚠️ Two things to know before you run this

1. **This project was generated without a local Flutter/Dart SDK available**, so `flutter analyze` /
   `flutter pub get` / `flutter build` have **not** been executed against it here. The code was written
   and reviewed carefully against the current stable Flutter/Dart/package APIs, and a manual
   bracket/import audit was done, but please run the verification steps below yourself before
   shipping, and fix anything your local toolchain flags (most likely: minor package version pins in
   `pubspec.yaml` if newer/older majors have shifted an API).
2. **There is no public Kaysan Properties API.** All content (projects, areas, developers, blogs,
   testimonials) is served from an in-memory mock dataset (`lib/services/mock/mock_data.dart`) modeled
   on what's publicly listed on the website. Every service/repository is written so that flipping
   `AppConfig.useMockData` to `false` and filling in `AppConfig.apiBaseUrl` switches to real HTTP calls
   with zero changes anywhere else in the app.

## Getting started

This repo ships the `lib/`, `pubspec.yaml`, and `assets/` — the Dart application code — but **not**
the native `android/`, `ios/`, `web/`, etc. host project folders, since generating those requires
running the Flutter SDK (which this environment didn't have available). Scaffold them first:

```bash
cd kaysan_properties
flutter create --org com.kaysanproperties --project-name kaysan_properties .
```

This fills in `android/`, `ios/`, and the platform manifests without touching your existing
`lib/pubspec.yaml/assets` (answer "yes" if it asks to overwrite — it only overwrites its own
boilerplate files like `.gitignore`, not your source). Then:

```bash
flutter pub get
flutter analyze          # fix anything flagged for your exact SDK/package versions
flutter test              # no tests are included yet — see "Testing" below
flutter run                # or: flutter build apk / flutter build ios
```

## Configuration required before production use

| What | Where | Notes |
|---|---|---|
| Google Maps API key | `android/app/src/main/AndroidManifest.xml` and `ios/Runner/AppDelegate.swift` | See below — required for the Location tab on Property Details. |
| Brand image assets | `assets/images/`, `assets/icons/` | Currently empty placeholders (`README.md` in each folder). `lib/core/constants/asset_paths.dart` lists expected filenames. Nothing in the app currently calls `Image.asset(...)` on these paths, so their absence won't break a build — they're scaffolding for when brand assets are supplied. |
| Real API base URL | `lib/core/config/app_config.dart` → `apiBaseUrl`, `useMockData` | Flip once a backend exists. |
| Fonts (optional) | `pubspec.yaml` (commented-out `fonts:` block) + `assets/fonts/` | App currently uses the Material default (Roboto/San Francisco). Uncomment and add `.ttf` files to use a custom brand font. |

### Google Maps setup

**Android** — add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

**iOS** — add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps // add alongside existing imports

// inside application(_:didFinishLaunchingWithOptions:), before super call returns:
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

Also ensure `ios/Runner/Info.plist` has location-usage strings if you later add "use my location":
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kaysan Properties uses your location to show nearby projects.</string>
```

### Required native permissions

Already assumed available by the plugins used (add explicitly if your Flutter template omits them):

- **Internet** (Android — usually default; add `<uses-permission android:name="android.permission.INTERNET" />` to `AndroidManifest.xml` if missing)
- **Phone call** (`tel:` links) — no manifest permission needed, `url_launcher` uses the system dialer.
- **iOS `LSApplicationQueriesSchemes`** in `Info.plist` if you want `canLaunchUrl` checks for `tel`, `mailto`, `https`, and WhatsApp (`whatsapp`) — add:
  ```xml
  <key>LSApplicationQueriesSchemes</key>
  <array>
      <string>tel</string>
      <string>mailto</string>
      <string>https</string>
      <string>whatsapp</string>
  </array>
  ```

## Architecture

```
lib/
├── core/
│   ├── config/        # AppConfig — mock/real API toggle, env values
│   ├── constants/      # AppConstants (copy/contact info), AssetPaths
│   ├── theme/          # AppColors, AppTextStyles, AppTheme (Material 3, light+dark)
│   ├── utils/          # Formatters, Validators, LauncherUtils (call/email/whatsapp/share)
│   └── routes/         # RouteNames, GoRouter config
├── models/              # ProjectModel, AreaModel, DeveloperModel, BlogModel,
│                        # TestimonialModel, EnquiryModel — all with fromJson/toJson
├── services/            # ApiService (Dio: timeout/retry/logging), NetworkService
│                        # (connectivity_plus), per-feature services (mock ⇄ real switch point)
├── repositories/        # Domain logic layer: filtering/sorting (ProjectsRepository),
│                        # favorites persistence (SharedPreferences), thin pass-throughs for
│                        # areas/blogs/enquiries
├── providers/           # Riverpod: DI graph, ProjectsController (AsyncNotifier),
│                        # ProjectFilterController (search/filter state), FavoritesController,
│                        # ThemeModeController, EnquiryController, network status stream
├── views/               # One folder per screen/feature, each with a `widgets/` subfolder
│                        # for screen-local widgets
└── widgets/             # Cross-screen reusable widgets: PropertyCard, shimmer skeletons,
                          # EmptyStateView, ContactActionsBar, AppNetworkImage
```

**State management** (Riverpod): App/Loading/Error state is modeled via `AsyncValue` on every
`AsyncNotifierProvider`/`FutureProvider` (projects, areas, developers, blogs, testimonials,
favorites, enquiry submission). Search/Filter state is a plain `Notifier<ProjectFilter>`. Theme
state persists via `SharedPreferences`. Network state is a `StreamProvider<bool>` wrapping
`connectivity_plus`, surfaced as an in-app offline banner in the main shell.

**Networking** (Dio): `ApiService` centralizes base URL, timeouts, a bounded retry for
transient/5xx failures, debug-only request/response logging, and translation of `DioException`
into the app's own `ApiException` types so the UI layer never touches Dio directly.

**Navigation** (GoRouter): a `StatefulShellRoute` hosts the four bottom-nav tabs (Home, Listings,
Favorites, More) — each keeps its own back-stack — while Property Details, Search, Areas, Blogs,
Contact and Legal pages are pushed full-screen on top.

## Features implemented

Splash · Home (hero carousel, featured projects, developers, areas, stats, testimonials, blogs) ·
Property Listings with search + multi-facet filter sheet + sort · Property Search · Property
Details (gallery, overview, floor plans, location map, amenities, register-interest form) ·
Areas + Area Details · Blogs + Blog Details · Favorites (persisted) · Contact (form + call/email/
WhatsApp/share) · About · Privacy Policy · Terms & Conditions · Light/Dark theme toggle · Loading
shimmer states · Empty states · Error states · No-Internet banner + full screen · Pull-to-refresh.

## Testing

No test files are included yet. Recommended starting points once the SDK is available locally:

```bash
flutter test                                   # after adding tests under test/
flutter analyze                                 # static analysis — should be zero-warning
flutter build apk --debug                        # confirms Android compiles
flutter build ios --debug --no-codesign          # confirms iOS compiles (macOS + Xcode required)
```

Suggested first unit tests: `ProjectsRepository.applyFilter` (pure function, easy to test
exhaustively), `Validators`, and `Formatters`.
