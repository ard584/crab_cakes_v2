import 'package:flutter/material.dart';

enum EditGridAction { cancel, abandon, update }

Future<EditGridAction> confirmUpdateEditGrid(
  BuildContext context,
  String prompt,
) async {
  final result = await showDialog<EditGridAction>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Confirm Update"),
        content: Text(prompt),
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
                      onPressed: () => Navigator.pop(context, EditGridAction.cancel),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, EditGridAction.update),
                      child: const Text("Update"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, EditGridAction.abandon),
                      child: const Text("Abandon Changes"),
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

  return result ?? EditGridAction.cancel;
}
