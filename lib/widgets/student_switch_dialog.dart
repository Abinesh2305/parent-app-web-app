import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/home_service.dart';

Future<void> showStudentSwitchDialog({
  required BuildContext context,
  required List<dynamic> students,
  required VoidCallback goHome,
}) async {
  final box = Hive.box('settings');

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Switch Student"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(s['name'] ?? 'Student'),
              subtitle: Text(
                "${s['class_name'] ?? ''} ${s['section_name'] ?? ''}",
              ),
              onTap: () async {
                // ✅ STORE ONLY STUDENT
                box.put('current_student', s);

                Navigator.pop(context);

                // 🔄 Refresh home data
                await HomeService.syncHomeContents();

                if (!context.mounted) return;

                // ⬅️ Go to home
                goHome();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
      ],
    ),
  );
}
