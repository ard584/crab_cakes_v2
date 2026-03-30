import 'package:flutter/material.dart';

Future<bool> confirmUpdate(BuildContext context, String prompt, ) async {

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Confirm Update"),
        content: Text(
          prompt
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              children: [
                SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Update"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );

  return result ?? false;
}