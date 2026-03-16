import 'package:flutter/material.dart';

import '../models/student.dart';

class StudentDialog {
  const StudentDialog._();

  static Future<Student?> show(
    BuildContext context, {
    required String title,
    Student? initial,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final ageCtrl = TextEditingController(text: initial != null ? initial.age.toString() : '');
    final addressCtrl = TextEditingController(text: initial?.address ?? '');

    return showDialog<Student>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name.';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters long.';
                      }
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                        return 'Name can only contain letters and spaces.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ageCtrl,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an age.';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Age must be a positive number.';
                      }
                      if (parsed > 120) {
                        return 'Age must be 120 or less.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an address.';
                      }
                      if (value.trim().length < 5) {
                        return 'Address must be at least 5 characters long.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final student = Student(
                  id: initial?.id,
                  name: nameCtrl.text.trim(),
                  age: int.parse(ageCtrl.text.trim()),
                  address: addressCtrl.text.trim(),
                );
                Navigator.of(context).pop(student);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
