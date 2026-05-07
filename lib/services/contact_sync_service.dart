import 'package:flutter_contacts/flutter_contacts.dart';

/// Syncs device contacts with FamilyHub.
class ContactSyncService {
  static Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  static Future<List<FamilyContact>> getContacts() async {
    final hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) return [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    return contacts
        .where((c) => c.phones.isNotEmpty)
        .map((c) => FamilyContact(
              id: c.id,
              name: c.displayName,
              phone: c.phones.first.number,
              email: c.emails.isNotEmpty ? c.emails.first.address : null,
            ))
        .toList();
  }
}

class FamilyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;

  FamilyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
      };
}
