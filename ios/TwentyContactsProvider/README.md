# TwentyContactsProvider

iOS 18+ Contact Provider extension. Twenty CRM people appear as a live **Twenty** container in the iOS Contacts app (not copied to iCloud).

## Already wired in this repo

- Target `TwentyContactsProvider` (`com.luciosoft.pocketcrm.contactsprovider`)
- Embedded in `Runner`
- App Group `group.com.luciosoft.pocketcrm` on Runner + this extension
- Snapshot file: App Group `Library/Application Support/twenty_people.json`

If the Xcode project target is missing after a merge, recreate it:

1. Open `ios/Runner.xcworkspace` in Xcode 16+.
2. File → New → Target → **Contact Provider Extension**.
3. Product Name: `TwentyContactsProvider`.
4. Bundle ID: `com.luciosoft.pocketcrm.contactsprovider`.
5. Language: Swift. Deployment target: **iOS 18.0**.
6. Replace generated sources with the files in this folder and `ios/Runner/TwentyContactsSnapshot.swift` (add that file to this target’s Compile Sources).
7. Signing & Capabilities → App Groups → `group.com.luciosoft.pocketcrm` (same on Runner).
8. Confirm Runner **Embed Foundation Extensions** includes `TwentyContactsProvider.appex`.
9. Extension point (Info.plist):
   - ExtensionKit: `com.apple.contact.provider.extension`
   - Legacy NSExtension: `com.apple.contactprovider`

Enable the App Group for the App ID in the Apple Developer portal, then regenerate provisioning profiles.
