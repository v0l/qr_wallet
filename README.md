# QR Wallet

Open source (MIT) offline wallet for loyalty cards, tickets and any other
QR / barcode you want to keep handy. Built with Flutter — runs on Android,
iOS, macOS, Linux, Windows and the web.

## Features

- **Store codes locally** — nothing leaves the device, no accounts, no network.
- **Many symbologies** — QR, Aztec, Data Matrix, PDF417, Code 128/39/93,
  EAN-13/8, UPC-A/E, ITF, Codabar.
- **Scan with the camera** (Android, iOS, macOS, web).
- **Import from an image** — pick a screenshot or photo and the code is
  extracted automatically.
- **Manual entry** with live preview and per-format validation.
- **Labels, colours and emoji icons** so cards are easy to pick out.
- **Fullscreen display at max brightness** — the view screen forces the screen
  to 100% brightness on a white background so scanners read it first time, and
  restores your brightness on exit.
- **Reorderable home list**, long-press a card to delete.
- **Backup export / import** as a single JSON file.

## Getting started

```bash
flutter pub get
flutter run                # attached device
flutter build apk --release
flutter build linux        # or macos / windows / web / ios
```

## Project layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | App entry, theme, store bootstrap |
| `lib/models/code_entry.dart` | `CodeEntry` model, `CodeFormat` enum, palette |
| `lib/store.dart` | JSON-file store (`codes.json`), atomic writes |
| `lib/backup.dart` | Export/import of the whole wallet |
| `lib/scan_utils.dart` | Format mapping, platform capabilities, QR image decode |
| `lib/screens/home_screen.dart` | Card list, add/scan/import actions, menu |
| `lib/screens/edit_screen.dart` | Create/edit a card with live preview |
| `lib/screens/scan_screen.dart` | Camera scanner + image import |
| `lib/screens/view_screen.dart` | Fullscreen code, max brightness |

## Branding

Source art lives in `branding/` as SVG; the PNGs consumed by the icon/splash
generators are rendered from it:

```bash
cd branding && npm install && npm run build   # SVG -> PNG (resvg)
cd .. && dart run flutter_launcher_icons       # app icons, all platforms
dart run flutter_native_splash:create          # native splash screens
```

| File | Used for |
| --- | --- |
| `branding/icon.svg` | Full app icon tile (iOS/macOS/Windows/web) |
| `branding/icon-foreground.svg` | Android adaptive icon foreground |
| `branding/splash.svg` | Native splash logo |
| `branding/splash-android12.svg` | Android 12+ splash icon (larger safe area) |

Palette: background `#0E1130`, code modules `#7C8CFF`, card accent `#33C39A`.

## Storage

Native platforms: `<app support dir>/codes.json`, written atomically
(temp file + rename). Web: the same JSON blob in local storage via
`shared_preferences`.

Schema:

```json
{
  "version": 1,
  "codes": [
    {
      "id": "uuid",
      "label": "Tesco Clubcard",
      "data": "634004024...",
      "format": "ean13",
      "color": 4280391411,
      "icon": "🛒",
      "note": null,
      "createdAt": "2026-01-01T12:00:00.000"
    }
  ]
}
```

## Platform notes

| Platform | Camera scan | Image import |
| --- | --- | --- |
| Android / iOS / macOS | ✅ `mobile_scanner` | ✅ all formats |
| Web | ✅ `mobile_scanner` | ⚠️ QR only (pure-Dart `zxing2` fallback) |
| Linux / Windows | ❌ not supported | ⚠️ QR only (pure-Dart `zxing2` fallback) |

Brightness control uses `screen_brightness` (Android, iOS, macOS, Windows);
elsewhere it degrades gracefully to a no-op.

## Dependencies

`barcode_widget` (rendering) · `mobile_scanner` (camera + native decode) ·
`zxing2` + `image` (pure-Dart QR decode) · `file_selector` ·
`path_provider` · `shared_preferences` · `screen_brightness` · `share_plus` ·
`uuid`

## License

MIT — see [LICENSE](LICENSE).

## CI

`.github/workflows/build.yml` runs `dart format` + `flutter analyze` and builds
release artifacts for Android (APK + AAB), iOS (unsigned IPA), macOS, Linux,
Windows and web on every push/PR. Pushing a `v*` tag publishes all artifacts to
a GitHub Release.

Artifacts are uploaded with `actions/upload-artifact@v7` and `archive: false`,
so `qr-wallet-android.apk` downloads un-zipped from the run page and installs
directly. The same raw files are also attached to the rolling
[`nightly`](https://github.com/v0l/qr_wallet/releases/tag/nightly) pre-release
(rebuilt on every push to `main`) and to tagged releases, where GitHub serves
the APK as `application/vnd.android.package-archive`.
