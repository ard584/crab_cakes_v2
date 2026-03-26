import 'package:flutter/material.dart';

Future<bool> confirmDelete(BuildContext context, String prompt) async {
  final textController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Confirm Delete"),
        content: Text(
          "$prompt"
          "\nType 'DELETE' to confirm",
        ),
        actions: [
          TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'DELETE',
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
          ),
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
                      onPressed: () {

                        if (textController.text.compareTo('DELETE') == 0) {
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pop(context, false);
                        }
                      },
                      child: const Text("Delete"),
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