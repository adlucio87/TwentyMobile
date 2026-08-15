import Flutter
import Foundation
import UIKit

#if canImport(ContactProvider)
import ContactProvider
#endif

enum IosContactsProviderPlugin {
    static let channelName = "com.luciosoft.pocketcrm/ios_contacts_provider"

    static func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "isSupported":
                if #available(iOS 18.0, *) {
                    result(true)
                } else {
                    result(false)
                }
            case "isEnabled":
                isEnabled(result: result)
            case "setEnabled":
                setEnabled(call: call, result: result)
            case "writeSnapshot":
                writeSnapshot(call: call, result: result)
            case "upsertContact":
                upsertContact(call: call, result: result)
            case "deleteContact":
                deleteContact(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func isEnabled(result: @escaping FlutterResult) {
        guard #available(iOS 18.0, *) else {
            result(false)
            return
        }
        #if canImport(ContactProvider)
        do {
            let manager = try ContactProviderManager()
            result(manager.isEnabled)
        } catch {
            result(false)
        }
        #else
        result(false)
        #endif
    }

    private static func setEnabled(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard #available(iOS 18.0, *) else {
            result(false)
            return
        }
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool
        else {
            result(FlutterError(code: "bad_args", message: "enabled is required", details: nil))
            return
        }
        #if canImport(ContactProvider)
        Task {
            do {
                let manager = try ContactProviderManager()
                if enabled {
                    try await manager.enable()
                    if manager.isEnabled {
                        try? await manager.signalEnumerator()
                    }
                } else if manager.isEnabled {
                    try await manager.disable()
                }
                result(manager.isEnabled)
            } catch {
                result(FlutterError(code: "set_enabled_failed", message: error.localizedDescription, details: nil))
            }
        }
        #else
        result(false)
        #endif
    }

    private static func writeSnapshot(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contacts = args["contacts"] as? [[String: Any]]
        else {
            result(FlutterError(code: "bad_args", message: "contacts is required", details: nil))
            return
        }
        do {
            try TwentyContactsSnapshot.write(contacts: contacts)
            signalIfEnabled()
            result(true)
        } catch {
            result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
        }
    }

    private static func upsertContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contact = args["contact"] as? [String: Any]
        else {
            result(FlutterError(code: "bad_args", message: "contact is required", details: nil))
            return
        }
        do {
            try TwentyContactsSnapshot.upsert(contact: contact)
            signalIfEnabled()
            result(true)
        } catch {
            result(FlutterError(code: "upsert_failed", message: error.localizedDescription, details: nil))
        }
    }

    private static func deleteContact(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? String, !id.isEmpty
        else {
            result(FlutterError(code: "bad_args", message: "id is required", details: nil))
            return
        }
        do {
            try TwentyContactsSnapshot.delete(id: id)
            signalIfEnabled()
            result(true)
        } catch {
            result(FlutterError(code: "delete_failed", message: error.localizedDescription, details: nil))
        }
    }

    private static func signalIfEnabled() {
        guard #available(iOS 18.0, *) else { return }
        #if canImport(ContactProvider)
        Task {
            do {
                let manager = try ContactProviderManager()
                if manager.isEnabled {
                    try await manager.signalEnumerator()
                }
            } catch {}
        }
        #endif
    }
}
