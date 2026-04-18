import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ui_prototype/presentation/components/usb_backups_section.dart';
import 'package:ui_prototype/presentation/components/scanner_target_section.dart';
import 'package:ui_prototype/presentation/components/pit_reader_section.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

// import your settings providers file
import 'package:ui_prototype/infrastructure/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            spacing: 16.0,
            children: <Widget>[
              const UsbBackupDrivesSection(),

              const ReusableLeftAlignedText(text: 'Paired PIT Readers'),
              const PitReadersSection(),

              const ScannerTargetSection(),

              const ReusableLeftAlignedText(text: 'Merge Data Files'),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.file_copy),
                    const SizedBox(width: 8),
                    const Text("Data File: 'project_5.db'"),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Import a data file to be merged.',
                      onPressed: () {
                        log.d('Tapped merge import');
                      },
                      icon: const Icon(Icons.file_upload),
                    ),
                  ],
                ),
              ),

              const ReusableLeftAlignedText(text: 'Project Configuration Export'),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.settings_suggest),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Export this project’s saved schema and settings to a JSON file.',
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Export Settings'),
                      onPressed: () async {
                        final exportUsecase =
                            ref.read(exportSettingsUsecaseProvider);

                        if (exportUsecase == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No active project is open, so settings cannot be exported.',
                              ),
                            ),
                          );
                          return;
                        }

                        try {
                          await exportUsecase.execute();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings exported successfully.'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to export settings: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final divider = Divider(height: 1.0, color: Colors.grey);

final reusableBoxDecoration = BoxDecoration(
  color: Colors.grey.shade100,
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

const reusablePadding = EdgeInsets.all(16);

class ReusableLeftAlignedText extends StatelessWidget {
  final String text;

  const ReusableLeftAlignedText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}