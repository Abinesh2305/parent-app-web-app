import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/student_manager.dart';

Future<void> showStudentSwitchDialog({
  required BuildContext context,
  required List<dynamic> students,
  required VoidCallback goHome,
}) async {
  final box = Hive.box('settings');
  bool switching = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Switch Student"),
            content: SizedBox(
              width: double.maxFinite,
              child: switching
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s =
                            Map<String, dynamic>.from(students[i]);

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                            s['name']?.toString() ?? 'Student',
                          ),
                          subtitle: Text(
                            "${s['class_name'] ?? ''} ${s['section_name'] ?? ''}",
                          ),
                          onTap: () async {
                            setState(() => switching = true);

                            // 🔐 Parent credentials (stored at login)
                            final parentEmail =
                                box.get('parent_email');
                            final parentPassword =
                                box.get('parent_password');

                            if (parentEmail == null ||
                                parentPassword == null) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please login again to switch student",
                                  ),
                                ),
                              );
                              return;
                            }

                            // 🔑 REQUIRED by backend
                            final studentUsername =
                                s['username'] ??
                                s['student_username'] ??
                                s['admission_no'];

                            if (studentUsername == null ||
                                studentUsername
                                    .toString()
                                    .isEmpty) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Invalid student data"),
                                ),
                              );
                              return;
                            }

                            // 🔁 RE-AUTH & SWITCH
                            final success =
                                await StudentManager.switchStudent(
                              parentEmail: parentEmail,
                              password: parentPassword,
                              student: s,
                              studentUsername:
                                  studentUsername.toString(),
                            );

                            if (!success) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Unable to switch student"),
                                ),
                              );
                              return;
                            }

                            // ✅ SUCCESS
                            Navigator.pop(dialogContext);
                            goHome();
                          },
                        );
                      },
                    ),
            ),
            actions: switching
                ? []
                : [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext),
                      child: const Text("CANCEL"),
                    ),
                  ],
          );
        },
      );
    },
  );
}
