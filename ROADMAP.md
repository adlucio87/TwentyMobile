# 🗺 TwentyMobile Roadmap

This document outlines recent milestones, network audit findings, and planned developments for **TwentyMobile**.

---

## 📌 Recent Milestones

### v1.0.16 — Privacy Hardening & On-Device Processing
- [x] **Settings Privacy Toggle**: User-facing toggle in **Settings → Privacy** to disable error reporting and performance tracking (GlitchTip) at runtime.
- [x] **Compile-Time Privacy Flag**: Support for `--dart-define=ERROR_REPORTING=false` to compile error reporting out completely (bypassing Sentry initialization and preventing initial DNS lookups).
- [x] **Content-Free GraphQL Error Reports**: Stripped CRM field values, record contents, and server validation messages from error reports (`GraphQLFailure` summary only).
- [x] **100% On-Device Voice Dictation**: Enforced `SpeechListenOptions(onDevice: true)` so audio never leaves the phone to external dictation servers (Apple `guzzoni.apple.com`).
- [x] **Diagnostic Data Scrubbing**: Stripped the installation `user.id`, console log breadcrumbs, and native UI events (view controllers, keyboard, screenshot notifications) from telemetry.

### v1.0.15 — Typography & Foundations
- [x] **Native Typography & Offline Fonts**: Bundled genuine Google Fonts Inter TTF binaries across all weights. Fully offline font rendering (`allowRuntimeFetching = false`) with zero external network requests.
- [x] **iOS 15.5+ Deployment Target & Dependencies**: Updated minimum iOS deployment target and upgraded CocoaPods (`MLKitVision 10.0.0`) for clean release builds.
- [x] **Release Tagging**: Standardized Git release tagging (`v1.0.15`, `v1.0.16`) mapping store binaries directly to reproducible commits.
- [x] **License Clarification**: Project license unambiguously aligned to **GNU AGPL-3.0**.
- [x] **Full Localization Parity**: 100% string translation coverage across 6 languages (EN, IT, FR, DE, ES, HI) with 130+ automated tests.
- [x] **iOS 18 Contacts Provider**: Live native Twenty CRM container in the Apple Contacts app via ExtensionKit.

---

## 🔒 Security, Privacy & Self-Hosted Enhancements

Based on our runtime proxy audit and community feedback for self-hosted instances (detailed in [doc/SECURITY_AUDIT.md](doc/SECURITY_AUDIT.md)):

- [ ] **Demo Mode Sandbox Architecture**:
  - Replace the static, long-lived Admin API key in `DemoConfig` with an authenticated demo user account (restricted `Member` role) or dynamically provisioned ephemeral tokens.
  - Implement backend-level read-only access and automated nightly database resets on `twentycrm.luciosoft.it`.
- [ ] **Custom DSN Support for Self-Hosters**:
  - Allow self-hosted administrators to specify their own private GlitchTip/Sentry DSN directly in Settings or via build flags, keeping crash analytics entirely on their infrastructure.
- [ ] **Strict Air-Gapped / Zero-External-Network Mode**:
  - Introduce an optional "Strict Privacy / Air-Gapped" toggle that blocks all non-CRM network requests:
    - Replace `twenty-icons.com` remote favicons with locally generated initials/avatars.
    - Suppress ML Kit telemetry logs (`play.googleapis.com`) or evaluate pure on-device OCR fallbacks.
    - Disable cloud CAPTCHA fallbacks on instances without public internet access.
- [ ] **Continuous Network Proxy Test Suite**:
  - Add an automated CI test verifying network egress behind a logging proxy (`mitmproxy`), asserting that zero traffic leaves the local CRM boundary when error reporting is disabled.

---

## 🎨 UI/UX & Polish

- [ ] **Voice Note Recording Visualizer Fix** (Issue [#48](https://github.com/adlucio87/TwentyMobile/issues/48)):
  - Resolve an issue in the recording bottom sheet (`VoiceNoteSheet`) where the animated microphone indicator renders improperly (appearing as a narrow vertical line on certain iOS/Android viewports).
  - Add a modern audio waveform or circular pulsing indicator with proper width constraints.
- [ ] **App Icon Harmonization & Android Adaptive Icon**:
  - **Unify Icon Branding**: Align the iOS and Android application icons (currently split between `assets/images/logo.png` and `assets/images/logo_ios.png`) to ensure a single, consistent visual identity across both platforms and stores.
  - **Modern Android Adaptive Icon (Material You / Android 13+)**:
    - Configure proper `adaptive_icon_background` and `adaptive_icon_foreground` in `flutter_launcher_icons`.
    - Enlarge and properly scale the foreground emblem with safe zone margins so the icon doesn't look clipped, squashed, or too small inside adaptive shapes (circle, squircle, pebble).
    - Match the background treatment and premium aesthetics of the iOS app icon.
- [ ] **Dynamic Objects Enhancements**:
  - Expand dynamic field support for complex nested relations and multi-select enum arrays.
  - Field reordering and visibility presets syncable across devices or stored per workspace.
  - Better empty-state illustrations and skeleton loaders across all dynamic record types.
- [ ] **Search & Filtering Upgrades**:
  - Advanced multi-filter support for custom objects (combining date ranges, status filters, and assigned actors).

---

## ⚙️ DevOps & Release Automation

- [ ] **Automated GitHub Actions CI/CD**:
  - **Pull Request Checks**: Automated Flutter analysis, formatting, and unit test execution (`flutter test`).
  - **Release Pipeline**: Automated creation of Android App Bundles (`.aab`) and iOS `.ipa` archives when a new release tag `v*` is pushed.
  - Automatic GitHub Releases creation with attached artifacts and auto-generated changelogs.
- [ ] **Fastlane Integration**:
  - Streamlined deployment pipelines for Google Play Internal Sharing and Apple TestFlight.

---

## 💡 Ideas & Future Explorations

- **Offline-First Synchronizer**: Local queue for mutations (contact edits, notes, task completions) with background sync when connectivity is restored.
- **Biometric App Lock**: Optional Face ID / Touch ID / Fingerprint lock upon opening the app.
- **Push Notification Gateway**: Optional self-hostable bridge for remote APNs/FCM push notifications on Twenty CRM webhooks.
