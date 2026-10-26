# Live Navigation (billing-free)

Isolated, Waze-inspired driving navigation with **no Google services, no API
keys, no account, and no credit card**:

| Layer | Implementation | Cost / account |
|---|---|---|
| Map rendering | MapLibre Native (`maplibre` plugin), OSM-based vector tiles | Open-source (BSD-3-Clause). Default style is OpenFreeMap "liberty" (keyless) — a free public service; respect fair use |
| Location | Device GPS via `geolocator` | Free, on-device |
| Routing | OSRM v1 API (`OsrmRoutingService`) | Open-source engine. Default endpoint is the public OSRM **demo server** — shared, rate-limited, no SLA |
| Destination | Map tap + manual coordinates | Free, offline |
| Place search | Not bundled (see `GeocodingProvider` contract) | — |

Nothing outside this folder may depend on it except the single entry card
in `lib/screens/home_screen.dart`.

## Disable / remove

- **Disable:** set `LiveNavFeatureFlag.enabled = false` in
  `live_navigation.dart`. The HomeScreen card hides itself; no map, GPS, or
  routing code runs.
- **Remove:** delete `lib/features/live_navigation/` and
  `test/features/live_nav/`, remove the HomeScreen card + imports, and
  remove `maplibre` / `geolocator` from `pubspec.yaml`. No other cleanup is
  needed — the feature adds zero native/API-key configuration.

## Production hardening (required before real use)

The defaults are development conveniences, NOT production backends:

1. **Tiles:** point `MAP_STYLE_URL` at your own style (e.g. a self-hosted
   `tileserver-gl` serving OpenMapTiles, or any MapLibre-compatible style
   you are allowed to use). The default public style is fair-use only and
   will throttle real traffic.
2. **Routing:** point `OSRM_BASE_URL` at your own OSRM instance (any
   server speaking the OSRM v1 route API works — that is the point of the
   `RoutingService` abstraction). The demo server is rate-limited and has
   no uptime guarantee.
3. **Search (optional):** implement `GeocodingProvider` (e.g. Nominatim —
   respect its usage policy — or self-hosted Photon/Pelias) and wire it
   into `DestinationBar`.

Overrides (no secrets involved):

```bash
flutter run --dart-define=MAP_STYLE_URL=<style-url> --dart-define=OSRM_BASE_URL=<osrm-url>
```

## Personalizing the map UI

- **Map appearance:** satellite (Esri World Imagery, keyless) by default;
  tap the layers button (top-right) to cycle
  Satellite → Streets → Bright → Light (street styles are keyless
  OpenFreeMap vector styles).
  A custom `MAP_STYLE_URL` build define appears as an extra "Custom" entry.
- **Colors:** edit `config/nav_theme.dart` — route line, alternatives,
  position dot + ring, destination pin, guidance banner, ETA accent, and
  Stop button all read from `NavTheme`, so one edit recolors the feature.

## Permissions

- **Android:** `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
  (already in the manifest), requested at runtime.
- **iOS:** `NSLocationWhenInUseUsageDescription` (already in Info.plist);
  run `cd ios && pod install` on a Mac before the first iOS build.
- The screen shows a guided gate (grant / open Settings / enable GPS)
  instead of crashing when permission is denied or GPS is off.

## Run

```bash
flutter run
```

Open **Live Navigation** on the home screen. No keys, no setup.

## Test manually

- **Map renders:** tiles load around Tangub City (needs internet for the
  default style; check the OSM attribution chip bottom-left). If the map
  stays on "Loading map…" for >12 s you will see a check-connection hint —
  tiles cannot load offline.
- **GPS location:** grant permission; the blue dot follows you.
- **Destination:** tap the map to drop a red pin (label + coordinates in
  the top bar), or use the pin button to type lat/lng. Clear button resets.
- **Route:** picking a destination auto-loads the preview (distance/time
  chips, alternatives when the server returns them) → Start.
- **Navigation mode:** banner shows next instruction + distance; bottom
  panel shows ETA + remaining; camera follows with heading/tilt; dragging
  the map pauses follow and a Recenter button appears; Stop returns to
  preview.
- **Rerouting:** leave the route (>60 m for 3+ fixes); banner shows
  "Rerouting…", then "Route updated." 45 s cooldown between auto-reroutes.

## Automated tests

```bash
flutter test test/features/live_nav/
```

Covers polyline decoding, geo math, guidance advance/reroute/cooldown/
arrival, and OSRM parsing + error mapping (mocked HTTP).

## Architecture (reports-ready)

`models/reports/` defines `ReportType` (traffic, accident, closure,
construction, hazard, police), `RoadReport`, and a `ReportRepository`
contract with an `InMemoryReportRepository`. Not wired into UI yet — a
future backend only implements the contract and injects it.

## Performance notes

- GPS stream uses an 8 m distance filter; guidance math throttled to 1 fix/s.
- Reroutes require 3 consecutive off-route fixes + 45 s cooldown.
- Routes requested only on destination select and on reroute — never per
  GPS fix.

## Known limitations

- Turn-by-turn is computed on-device from OSRM steps (`guidance_engine.dart`
  is the seam where a native Navigation SDK could plug in later).
- MapLibre on Windows/macOS renders through a WebView (needs WebView2 on
  Windows); mobile (Android/iOS) uses the native SDKs.
- Offline maps require pre-packaged tiles (not bundled); without internet
  the map is empty but GPS + guidance math still run on a loaded route.

