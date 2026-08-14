import ContactProvider
import Contacts
import Foundation

@available(iOS 18.0, *)
@main
class TwentyContactsProvider: ContactProviderExtension {
    private let enumerator = TwentyPeopleEnumerator()

    required init() {}

    func configure(for domain: ContactProviderDomain) {
        enumerator.configure(for: domain)
    }

    func enumerator(for collection: ContactItem.Identifier) -> any ContactItemEnumerator {
        enumerator
    }

    func invalidate() async {
        await enumerator.invalidate()
    }
}

@available(iOS 18.0, *)
final class TwentyPeopleEnumerator: ContactItemEnumerator {
    func configure(for domain: ContactProviderDomain) {}

    func enumerateContent(in page: ContactItemPage, for observer: any ContactItemContentObserver) {
        let snapshot = TwentyContactsSnapshot.load()
        let generation = snapshot.generationData
        let items = snapshot.contacts.compactMap { Self.contactItem(from: $0) }
        let offset = page == .initialPage ? 0 : page.offset
        let pageSize = max(observer.suggestedPageSize, 1)

        guard offset <= items.count else {
            observer.didFinishEnumeratingContent(upTo: generation)
            TwentyContactsSnapshot.storeEnumeratedIds(snapshot.ids)
            return
        }

        let end = min(offset + pageSize, items.count)
        observer.didEnumerate(Array(items[offset..<end]))

        if end < items.count {
            let nextPage = ContactItemPage(generationMarker: generation, offset: end)
            observer.didFinishEnumeratingPage(upTo: nextPage)
        } else {
            TwentyContactsSnapshot.storeEnumeratedIds(snapshot.ids)
            observer.didFinishEnumeratingContent(upTo: generation)
        }
    }

    func enumerateChanges(startingAt syncAnchor: ContactItemSyncAnchor, for observer: any ContactItemChangeObserver) {
        let snapshot = TwentyContactsSnapshot.load()
        let currentIds = Set(snapshot.ids)
        let previousIds = Set(TwentyContactsSnapshot.lastEnumeratedIds())
        let deleted = previousIds.subtracting(currentIds).map { ContactItem.Identifier($0) }
        let items = snapshot.contacts.compactMap { Self.contactItem(from: $0) }
        let nextAnchor = ContactItemSyncAnchor(generationMarker: snapshot.generationData, offset: 0)

        observer.didUpdate(items)
        observer.didDelete(deleted)
        observer.didFinishEnumeratingChanges(upTo: nextAnchor, moreComing: false)
        TwentyContactsSnapshot.storeEnumeratedIds(snapshot.ids)
    }

    func invalidate() async {}

    private static func contactItem(from person: TwentyContactsSnapshot.Person) -> ContactItem? {
        let contact = CNMutableContact()
        contact.givenName = person.givenName
        contact.familyName = person.familyName
        if let email = person.email {
            contact.emailAddresses = [
                CNLabeledValue(label: CNLabelWork, value: email as NSString),
            ]
        }
        if let phone = person.phone {
            contact.phoneNumbers = [
                CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phone)),
            ]
        }
        if let organization = person.organization {
            contact.organizationName = organization
        }
        return ContactItem.contact(contact, ContactItem.Identifier(person.id))
    }
}
