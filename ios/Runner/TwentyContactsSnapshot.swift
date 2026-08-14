import Foundation

enum TwentyContactsSnapshot {
    static let appGroupId = "group.com.luciosoft.pocketcrm"
    static let fileName = "twenty_people.json"
    static let lastIdsKey = "twenty_people_last_ids"

    struct Person: Sendable {
        let id: String
        let givenName: String
        let familyName: String
        let email: String?
        let phone: String?
        let organization: String?
    }

    struct Payload: Sendable {
        let generation: String
        let contacts: [Person]

        var generationData: Data {
            Data(generation.utf8)
        }

        var ids: [String] {
            contacts.map(\.id)
        }
    }

    static var directoryURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
    }

    static var fileURL: URL? {
        directoryURL?.appendingPathComponent(fileName)
    }

    static func load() -> Payload {
        guard let fileURL,
              let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return Payload(generation: "empty", contacts: [])
        }

        let generation = (json["generation"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "empty"
        let rawContacts = json["contacts"] as? [[String: Any]] ?? []
        let contacts = rawContacts.compactMap { map -> Person? in
            guard let id = map["id"] as? String, !id.isEmpty else { return nil }
            return Person(
                id: id,
                givenName: map["givenName"] as? String ?? "",
                familyName: map["familyName"] as? String ?? "",
                email: nonempty(map["email"] as? String),
                phone: nonempty(map["phone"] as? String),
                organization: nonempty(map["organization"] as? String)
            )
        }
        return Payload(generation: generation, contacts: contacts)
    }

    static func write(contacts: [[String: Any]]) throws {
        guard let directoryURL, let fileURL else {
            throw NSError(
                domain: "TwentyContactsSnapshot",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "App Group container is unavailable"]
            )
        }

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let sanitized: [[String: Any]] = contacts.compactMap { raw in
            guard let id = raw["id"] as? String, !id.isEmpty else { return nil }
            var item: [String: Any] = [
                "id": id,
                "givenName": raw["givenName"] as? String ?? "",
                "familyName": raw["familyName"] as? String ?? "",
            ]
            if let email = nonempty(raw["email"] as? String) {
                item["email"] = email
            }
            if let phone = nonempty(raw["phone"] as? String) {
                item["phone"] = phone
            }
            if let organization = nonempty(raw["organization"] as? String) {
                item["organization"] = organization
            }
            return item
        }

        let payload: [String: Any] = [
            "generation": ISO8601DateFormatter().string(from: Date()),
            "contacts": sanitized,
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        let tempURL = directoryURL.appendingPathComponent("\(fileName).tmp")
        try data.write(to: tempURL, options: .atomic)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(fileURL, withItemAt: tempURL)
        } else {
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
        }
    }

    static func lastEnumeratedIds() -> [String] {
        UserDefaults(suiteName: appGroupId)?.stringArray(forKey: lastIdsKey) ?? []
    }

    static func storeEnumeratedIds(_ ids: [String]) {
        UserDefaults(suiteName: appGroupId)?.set(ids, forKey: lastIdsKey)
    }

    private static func nonempty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
