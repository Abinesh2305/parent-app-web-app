import 'package:flutter/material.dart';
import 'package:school_dashboard/l10n/app_localizations.dart';
import '../services/contacts_service.dart';
import 'contacts_list_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool loading = true;
  List<dynamic> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final res = await ContactsService().getContactsList();
    if (!mounted) return;

    setState(() {
      loading = false;
      categories = (res != null && res['status'] == 1) ? res['data'] : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.schoolContacts)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
              ? Center(child: Text(t.noContacts))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final c = categories[index];

                    return Card(
                      elevation: 2,
                      color: cs.surface,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        title: Text(
                          c['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: cs.primary,
                          ),
                        ),
                        // subtitle: Text(
                        //   "${t.category}: ${c['contact_for']}",
                        //   style: TextStyle(
                        //     fontSize: 13,
                        //     color: cs.onSurface.withOpacity(0.7),
                        //   ),
                        // ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: cs.onSurface.withOpacity(0.5),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContactsListScreen(
                                categoryName: c['name'],
                                contacts: c['contacts_list'] ?? [],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
