import 'package:flutter_test/flutter_test.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/services/ios_contacts_provider_service.dart';

void main() {
  group('contactToIosSnapshot', () {
    test('maps a full contact including company', () {
      final contact = Contact(
        id: 'person-1',
        firstName: 'Alex',
        lastName: 'Dupont',
        email: 'alex@example.com',
        phone: '+33123456789',
        companyName: 'Luciosoft',
      );

      expect(contactToIosSnapshot(contact), {
        'id': 'person-1',
        'givenName': 'Alex',
        'familyName': 'Dupont',
        'email': 'alex@example.com',
        'phone': '+33123456789',
        'organization': 'Luciosoft',
      });
    });

    test('keeps empty names and omits missing email and phone', () {
      final contact = Contact(
        id: 'person-2',
        firstName: '',
        lastName: '',
        companyName: 'Acme',
      );

      final snapshot = contactToIosSnapshot(contact);

      expect(snapshot, {
        'id': 'person-2',
        'givenName': '',
        'familyName': '',
        'organization': 'Acme',
      });
      expect(snapshot.containsKey('email'), isFalse);
      expect(snapshot.containsKey('phone'), isFalse);
    });

    test('does not include empty email or phone keys', () {
      final contact = Contact(
        id: 'person-3',
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: '   ',
        phone: '',
        companyName: '  ',
      );

      final snapshot = contactToIosSnapshot(contact);

      expect(snapshot, {
        'id': 'person-3',
        'givenName': 'Ada',
        'familyName': 'Lovelace',
      });
      expect(snapshot.containsKey('email'), isFalse);
      expect(snapshot.containsKey('phone'), isFalse);
      expect(snapshot.containsKey('organization'), isFalse);
    });
  });
}
