# 🗺 TwentyMobile Roadmap

This document outlines the current project status, recent audit findings, and planned developments for **TwentyMobile**.

---

## 📌 Recent Milestones (v1.0.15)

- [x] **Native Typography & Offline Fonts**: Replaced corrupted font assets with genuine Google Fonts Inter TTF binaries across all weights. Fully offline font rendering (`allowRuntimeFetching = false`) with zero external network requests.
- [x] **iOS 15.5+ Deployment Target & Dependencies**: Updated minimum iOS deployment target and upgraded CocoaPods (`MLKitVision 10.0.0`) for clean release builds.
- [x] **Release Tagging**: Introduced standardized Git release tagging (starting with `v1.0.15`) mapping store binaries directly to reproducible commits.
- [x] **License Clarification**: Project license unambiguously aligned to **GNU AGPL-3.0**.
- [x] **Full Localization Parity**: 100% string translation coverage across 6 languages (EN, IT, FR, DE, ES, HI) with 124+ automated tests.
- [x] **iOS 18 Contacts Provider**: Live native Twenty CRM container in the Apple Contacts app via ExtensionKit.

---

## 🔒 Security, Privacy & Self-Hosted Enhancements

Based on our runtime network audit and community feedback for self-hosted instances:

- [ ] **Sentry/GlitchTip Privacy Opt-Out Toggle**:
  - Add a user-facing toggle in **Settings** to completely disable error monitoring and performance tracing at runtime.
  - Optional: allow self-hosted administrators to specify their own custom Sentry/GlitchTip DSN.
- [ ] **Strict PII & Hostname Sanitization in Crash Reports**:
  - Implement a `beforeSend` sanitizer to strip internal hostnames, custom domain URLs, and server responses from uncaught exception hints before dispatching to error reporting.
- [ ] **Transparent Network & Privacy Audit Documentation**:
  - Maintain a verified map of all runtime network endpoints (`twenty-icons.com`, CAPTCHA providers, on-device ML Kit, and local push notifications).

---

## 🎨 UI/UX & Polish

- [ ] **Voice Note Recording Visualizer Fix**:
  - Resolve an issue in the recording bottom sheet (`VoiceNoteSheet`) where the animated microphone/waveform indicator renders improperly (appearing as a narrow vertical line on certain iOS/Android viewports).
  - Add a modern audio waveform or circular pulsing indicator with proper width constraints.
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
