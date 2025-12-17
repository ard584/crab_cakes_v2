import 'package:flutter/material.dart';
import 'package:ui_prototype/exceptions/project_db_exception.dart';

Future<void> showProjectDbErrorDialog(
  BuildContext context,
  ProjectDbException e,
) {
  final message = switch (e.type) {
    ProjectDbErrorType.openFailed =>
      'This project could not be opened.\n\n'
          'The database file may have been moved or deleted.',
    ProjectDbErrorType.invalidSchema =>
      'This project was created with an incompatible version.',
    ProjectDbErrorType.readFailed =>
      'An error occurred while reading the project data.',
  };

  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Failed to Open Project'),
      content: Column(
        children: [
          Text(message),
          Text(
            e.additionalMessage ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
