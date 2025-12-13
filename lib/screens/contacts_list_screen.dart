import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';

class ContactsListScreen extends StatelessWidget {
  final String categoryName;
  final List<dynamic> contacts;

  const ContactsListScreen({
    super.key,
    required this.categoryName,
    required this.contacts,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: contacts.isEmpty
          ? Center(child: Text(t.noContacts))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final c = contacts[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['contact_name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                        if (c['contact_mobile'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text("Mobile: ${c['contact_mobile']}"),
                          ),
                        if (c['contact_email'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text("Email: ${c['contact_email']}"),
                          ),
                        if (c['contact_info'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text("Info: ${c['contact_info']}"),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
