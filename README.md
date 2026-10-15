# TwentyMobile

TwentyMobile is a native mobile application developed with **Flutter** that serves as a unified client for CRM backends, starting with an integration with **Twenty CRM**. The project's goal is to allow users to manage contacts, companies, notes, and tasks on the go, with a modern, fast, and responsive interface.

**Official Website:** [twentymobilecrm.luciosoft.it](https://twentymobilecrm.luciosoft.it/)



**Project Namespace:** `com.luciosoft.pocketcrm`

## 🌟 Implemented Features

- **Onboarding & Authentication:** Connection to a self-hosted Twenty CRM instance via URL with multiple access modes: **OAuth 2.0 PKCE** in the system browser (for standard/SSO users), **Email/Password**, or **API Token** (for administrators). Secure credential storage and integration with Sentry for error monitoring.
- **Demo Mode:** Full exploration of the interface and features through an isolated test environment with a security lock on mutations.
- **Dashboard (Home):** A quick overview to start the day, featuring dynamic greetings, upcoming tasks, today's tasks, and recently viewed contacts.
- **Contact Management:**
  - Interactive contact list with quick search functionality.
  - Comprehensive contact detail view.
  - Rapid creation and editing of contacts with **optimistic updates** (Optimistic UI).
  - Contact sharing and direct export to the system's address book (iOS/Android).
  - **iOS 18+ Contacts Provider:** Settings toggle *Show Twenty people in iOS Contacts* adds a live **Twenty** account in the iOS Contacts app. People stay in a provider container (not copied to iCloud).
  - Rapid capture via integrated **Business Card Scanner**.
  - Quick actions for sending emails or starting phone calls.
- **Company Management:**
  - Company list and dedicated detail page with linked contacts.
  - Fast opening of company websites in the native browser.
- **Advanced Notes:**
  - Chronological view of linked notes.
  - Quick text note taking from details or home screen.
  - Secure **Voice Note** recording, allowing you to dictate and save information hands-free.
- **Task Management & Notifications:**
  - List of assigned tasks with dynamic filtering (To Do / Completed).
  - **Task Assignment:** Support for assigning tasks to specific workspace members (automatic for email login, manual via dropdown for admins).
  - Scheduling with due dates.
  - Advanced notification system (local push notifications) to remind about upcoming or overdue tasks.
- **Manual Workflows:**
  - Fast execution of manual workflows directly from Contact and Company detail views via a quick action (⚡ *bolt icon*) in the AppBar.
  - Multi-step interactive flow (**Bottom Sheet**) including active workflow selection, real-time loading (shimmer effect), and empty state.
  - **Dynamic Input Forms:** Automatically renders input fields based on workflow schema constraints, with support for types such as `TEXT`, `NUMBER`, `SELECT` (dropdown), and `BOOLEAN` (switch).
  - Premium **Slide-to-Execute** confirmation button with anti-fat-finger threshold, linear haptic feedback progress, and shake feedback animation on errors.
- **Dynamic & Custom Workspace Objects (More Section):**
  - Full support for standard or custom CRM objects (e.g. Opportunities, custom reports) defined dynamically on the Twenty CRM backend.
  - Generates GraphQL queries and mutations on the fly using runtime metadata.
  - Lists workspace objects, including pagination (infinite scroll), text search, and pull-to-refresh.
  - **Dynamic Detail View:** Inspects record properties, orders them, and lets users toggle their visibility (preferences saved locally per-object type via Hive).
  - **Dynamic Form Engine:** Creates, edits, and saves dynamic records. Provides specialized fields for complex types:
    - *Currency:* Dual-input for numeric amount (automatically converting to/from micros) and currency code.
    - *Relations:* Searchable lookup pickers for linked contacts and companies.
    - *Full Name, Emails, Phones, Links, Addresses:* Multi-field composite inputs that structure data precisely as expected by the Twenty CRM schema.
- **UI/UX & Localization:**
  - Multi-language support with translations available in **English (US/UK), Italian, French, German, and Hindi**.
  - Users can switch languages directly from the Settings menu.
  - Robust adaptive layouts for software keyboard handling (preventing unintended rebuilds and text selections).
  - Automatic cache invalidation on user change to ensure the integrity of displayed data.

## ⚡ Dynamic & Custom Workspace Objects Configuration

PocketCRM dynamically fetches metadata for all workspace objects via Twenty CRM's GraphQL API. 

* **Fields Visibility & Sorting:** From any dynamic object's detail screen, press the ⚙/⚡ settings icon to toggle which fields are visible and customize their display order. These settings are persisted locally.
* **Relations Editing Support:** 
  - Fields pointing to a `Company` open the **Company Picker Bottom Sheet**.
  - Fields pointing to a `Person`/`Contact` open the **Contact Picker Bottom Sheet**.
  - `ACTOR` fields (like `createdBy`, `updatedBy`) are strictly read-only and point to their respective creators without allowing direct editing, keeping the workspace secure.
* **Complex/Composite Fields:** Input formats for Address, Currency, and Phone numbers are automatically structured to match Twenty's native DB types.

## 🔐 Authentication Modes & Setup Guide

TwentyMobile supports three distinct authentication methods to connect to your Twenty CRM instance:

### 1. Google / SSO Login (OAuth 2.0 PKCE) — Recommended for Teams

PocketCRM signs in through Twenty's native OAuth 2.0 authorization-code flow with **PKCE** (RFC 7636) opened directly in the **system browser** (Chrome Custom Tabs on Android / ASWebAuthenticationSession on iOS). This ensures that login credentials (like Google accounts) are never entered into an in-app browser, and sessions on shared devices are kept strictly isolated.

#### Automatic vs. Manual Setup:

* ✨ **Zero-Touch Automatic Registration (Twenty Cloud & Supported Instances):**  
  TwentyMobile implements **Dynamic Client Registration (RFC 7591)**. If your instance exposes a registration endpoint (default on `twenty.com` cloud instances), TwentyMobile registers the "TwentyMobile" application automatically in the background, generates a Client ID, and stores it in secure storage. **You do not need to create anything manually!**
  > *Note on Reinstallation:* Uninstalling the app clears the local secure storage. A fresh install first asks the shared team registry (see below) and only falls back to a new registration when nothing is registered for your instance. You can safely remove older, inactive "TwentyMobile" entries in Twenty CRM (*Settings → Applications*).

* 🛠️ **Manual Setup (Fallback for Self-Hosted Instances):**  
  If your self-hosted instance does not have dynamic registration enabled, follow these simple steps:
  1. **Create the Application on Twenty CRM:** Go to **Settings → Applications → Create Application** and name it **"TwentyMobile"**.
  2. **Register the Redirect URI:** Enter the exact Redirect URI displayed in TwentyMobile:
     - **Single-workspace** *(default self-hosted)*: `https://<your-instance>/auth/oauth-propagator/callback`
     - **Multi-workspace / Custom domain**: `https://twentymobilecrm.luciosoft.it/oauth/callback`
     *(Use the one-tap copy button in TwentyMobile)*
  3. **Copy the Client ID:** Save the app in Twenty CRM and paste the generated **Client ID** into TwentyMobile.
  4. **Sign in with Browser:** Tap **Sign in with Browser** to authenticate.

#### 🤝 Shared Client ID Registry (Team Onboarding)

The first teammate who connects an instance publishes the *verified* Client ID to a small public registry, so everybody else entering the same URL finds it pre-filled: one `TwentyMobile` application serves the whole workspace, and nobody has to repeat the manual steps or paste UUIDs around.

* **What it stores** (Firestore, region `europe-west1`): the instance **hostname**, the public **Client ID**, the application name, the verification timestamps and the previously overwritten IDs (audit trail). It never stores secrets, tokens, user accounts or CRM data.
* **What it verifies**: the Client ID must be confirmed by the instance itself (public `POST /metadata` GraphQL query) and belong to an application named `TwentyMobile`/`PocketCRM`; anything else is rejected. Entries are re-verified lazily (5 min TTL) and purged automatically when the application is deleted in Twenty CRM.
* **Hardening**: the endpoint refuses to call non-public hostnames (no IP literals, no `.internal`/private ranges, DNS answers are re-checked), accepts only Client IDs the instance itself confirms and applications named `TwentyMobile`/`PocketCRM`, never echoes back what a third-party host answered, and applies best-effort rate limits per caller and per instance. Those limits are held in memory per Cloud Function instance, so for hard global quotas add Firebase App Check or Cloud Armor.
* **Opt out / self-host the registry**: build the app with `--dart-define=OAUTH_REGISTRY_URL=` to disable the feature completely, or point it at your own deployment:

```bash
flutter run --dart-define=OAUTH_REGISTRY_URL=https://your.domain/api/oauth-client
```

Backend code and unit tests live in `backend/` (`npm --prefix backend test`); the quality gate covers them with `./scripts/verify.sh --area backend`. Deploy it with:

```bash
npm --prefix backend run deploy   # functions + hosting + firestore rules
```

Optional environment variables: `OAUTH_REGISTRY_ALLOWED_ORIGINS` (browser origins allowed by CORS), `OAUTH_REGISTRY_VERIFY_TIMEOUT_MS`, `OAUTH_REGISTRY_VERIFY_TTL_SECONDS`.

> [!NOTE]
> **First-Time Browser Sign-In (Landing on Twenty Dashboard):**  
> If your browser does not yet have an active Twenty CRM session, logging in with your credentials or Google SSO will navigate to your Twenty workspace dashboard first (an upstream Single Page Application routing behavior in Twenty CRM).  
> **Do not close the browser window.** Simply tap the browser's **Back** button on Android (or swipe from left edge / tap Cancel and reopen on iOS). This takes you back to the authorization URL where Twenty CRM recognizes your active session and presents the **"Connect TwentyMobile to your account"** consent prompt. Click **Authorize** to complete the login and return to the app automatically. Subsequent logins will reuse your browser session seamlessly.

---

### 2. Email & Password Login (Standard Users & Admins)

Authenticate directly using your Twenty CRM email and password:
- **Two-Factor Authentication (2FA/OTP):** If 2FA is configured on your account, the app automatically transitions to an OTP verification screen to enter your 6-digit code.
- **Automated Captcha Support:** If your instance enforces Cloudflare Turnstile or Google reCAPTCHA, TwentyMobile handles verification transparently in the background.
- **Required for Workflows:** Executing Twenty CRM manual workflows requires logging in with Email & Password (which yields a user JWT token).

---

### 3. API Key (Administrator / Direct Access)

Connect directly using a Twenty CRM API Key:
1. In Twenty CRM, navigate to **Settings → Developers → API Keys**.
2. Click **Create API Key**, configure the desired permissions (e.g. full workspace access), and copy the token.
3. In TwentyMobile, select **Login with API Key** and paste the token.

> [!NOTE]
> Triggering Twenty CRM **Manual Workflows** is currently restricted by Twenty's API when authenticated via API Key (returns 403 Forbidden). For workflow execution, use Email & Password login.

---

#### Custom OAuth Bouncer (Optional)
If deploying your own HTTPS bouncer rather than using the built-in domain:
```bash
flutter run --dart-define=OAUTH_REDIRECT_URI=https://your.domain/oauth/callback
```

## iOS Contacts Provider (iOS 18+)

On iOS 18 or later, open **Settings → iOS Contacts** and enable **Show Twenty people in iOS Contacts**. Twenty people then appear as a live container named **Twenty** in the system Contacts app. This is not a one-off vCard export and does not copy contacts into iCloud. Disable the toggle or log out to remove the container.

## ⚡ Workflow Integration & Requirements

PocketCRM supports running Twenty CRM manual workflows directly from the contact or company detail views. To use this feature successfully, please review the requirements and limitations below:

### 🔑 Authentication Requirement
* **Email & Password Login Required:** To execute workflows, you **must log in using your admin Email and Password** (which generates a JWT token).
* **API Key Limitation:** Using a Twenty API Key (even with full Admin permissions) will result in a `FORBIDDEN` (403) resource error from the Twenty GraphQL endpoint when attempting to trigger a workflow. This is an upstream limitation of the Twenty API.

### 📋 Supported Workflows & Triggers
* **Trigger Type:** Only workflows with a **Manual** trigger type set to `ACTIVE` will be displayed.
* **Entity-Specific Filtering:** 
  * Workflows configured for the `Company` entity (or with `availability.objectNameSingular` set to `company`) will appear on the **Company Details** screen.
  * Workflows configured for the `Person`/`People` entity (or with `availability.objectNameSingular` set to `person`/`contact`) will appear on the **Contact Details** screen.
  * Workflows configured as `GLOBAL` (no specific entity target) will be available on both detail screens.

### ⚠️ Interactive Form/Input Steps Limitation
* **Non-Interactive Workflows Only:** Workflows should be designed to execute fully automated backend actions (e.g., sending HTTP requests, updating database records, sending Slack notifications).
* **Interactive Steps Do Not Work:** Workflows that contain standard **web-based Form / interactive steps** (where Twenty expects a user to fill in text or press a button inside the Twenty web app during execution) **will hang in the `running` state** indefinitely when triggered via the API.
* **PocketCRM Warning:** PocketCRM automatically detects workflows containing web-based form steps and displays a warning badge: `⚠ Contains form step (may require web app)`.

## 🏛 Architecture and Project Structure

The architecture follows **Domain-Driven Design (DDD)** principles combined with a **Feature-First** approach in the presentation layer. The app uses the **Connector Pattern** to abstract calls to the source CRM.
An abstract `CRMRepository` interface is implemented by `TwentyConnector` (acting as a Facade that delegates to specific domain repositories like `TwentyContactRepository`, `TwentyCompanyRepository`, etc.). This allows for future expansions to other CRMs without modifying business logic or the UI.

The structure inside `lib/` is organized by feature:

```text
lib/
├── core/                           # Global DI (Riverpod), Router, Theme, StorageService, Auth, Localization
├── domain/                         # Core data models (Contact, Company, Task...), Repository interfaces (`CRMRepository`)
├── data/                           # Infrastructure and Implementation
│   ├── connectors/                 # BaseGraphQLConnector, TwentyConnector (Facade), DynamicObjectConnector
│   ├── repositories/               # Domain-specific repositories (Contact, Company, Task, Note, Workflow)
│   └── graphql/                    # Centralized GraphQL queries (crm_queries.dart, auth_mutations.dart)
├── presentation/                   # UI Layer (Feature-First)
│   ├── onboarding/                 # Initial setup and Demo access
│   ├── home/                       # Dashboard 
│   ├── contacts/                   # Contact module
│   ├── contact_detail/             # Contact details, voice note player/recorder
│   ├── companies/                  # Company module
│   ├── scan/                       # Business card scanner
│   ├── notes/                      # Text notes module
│   ├── tasks/                      # Tasks module
│   ├── workflows/                  # Manual Workflows module (lists, dynamic forms, slide-to-confirm)
│   └── dynamic_objects/            # Support for Custom/Dynamic Workspace objects (lists, preferences, detail, form engine)
│   shared/                         # Aesthetic widgets and cross-feature components (e.g., Demo block, pickers)
```

## 🛠 Main Technology Stack

- **Framework:** Flutter (Mobile, iOS/Android ready)
- **State Management & DI:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- **Multi-Path Routing:** GoRouter
- **API Integrations:** GraphQL (`graphql_flutter`)
- **Code Generation:** Freezed & JSON Serializable
- **Notifications:** `flutter_local_notifications`, `timezone`
- **Security & Storage:** Flutter Secure Storage, Hive

## 🚀 Development and Setup

To start the project locally:

1. Ensure you have the Flutter SDK (3.10+) installed.
2. Pull dependencies:
   ```bash
   flutter pub get
   ```
3. Regenerate the code for models and providers (Riverpod & Freezed):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run unit and widget tests:
   ```bash
   flutter test
   ```
5. Launch the app on a simulator or physical device:
   ```bash
   flutter run
   ```

## 🏗 Building for Release (Production)

Store builds correspond to official Git tags (e.g. `v1.0.15`). The version and build number are defined in `pubspec.yaml` (`version: X.Y.Z+BUILD`).

### 🤖 Android (Google Play Store)
Ensure release signing credentials are configured in `android/key.properties`, then generate the signed Android App Bundle:
```bash
flutter build appbundle --release
```
The output file is generated at:
`build/app/outputs/bundle/release/app-release.aab`

### 🍎 iOS (App Store / TestFlight)
1. Verify CocoaPods and native dependencies are up to date:
   ```bash
   cd ios && pod install && cd ..
   ```
   *(Note: The minimum iOS deployment target is iOS 15.5).*
2. Build the signed iOS App Store archive and `.ipa` package:
   ```bash
   flutter build ipa --release
   ```
The output IPA is placed at:
`build/ios/ipa/TwentyMobile.ipa`

You can distribute the `.ipa` using **Apple Transporter** or via the CLI:
```bash
xcrun altool --upload-app --type ios -f build/ios/ipa/TwentyMobile.ipa --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

## 🗺 Roadmap
For upcoming features, privacy controls, UI enhancements, and future plans, check out the [ROADMAP.md](ROADMAP.md).

## 🛡️ Security & Privacy Audit
TwentyMobile is designed with data sovereignty for self-hosted CRM instances. For a detailed breakdown of all runtime network endpoints, proxy verification, and hardening options, see [doc/SECURITY_AUDIT.md](doc/SECURITY_AUDIT.md).

## 📄 License
TwentyMobile is an open-source project distributed under the **AGPL-3.0** license.

