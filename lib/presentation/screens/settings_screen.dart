import 'package:flutter/material.dart';
import 'package:ui_prototype/presentation/components/usb_backups_section.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';
import 'package:ui_prototype/presentation/components/scanner_target_section.dart';

//importing the specific sccanner connection component
import 'package:ui_prototype/presentation/components/pit_reader_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ SOLUTION: Always start a new screen with a Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // The back button is automatically provided by the Scaffold/Navigator
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            spacing: 16.0,
            children: <Widget>[
              const UsbBackupDrivesSection(),
              ReusableLeftAlignedText(text: 'Paired PIT Readers'),
              const PitReadersSection(),
              const ScannerTargetSection(),
              ReusableLeftAlignedText(text: 'Merge Data Files'),
              Container(
                decoration: reusableBoxDecoration,
                padding: reusablePadding,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.file_copy),
                    const SizedBox(width: 8),
                    Text('Data File: \'project_5.db\''),
                    Spacer(),
                    IconButton(
                      tooltip: 'Import a data file to be merged.',
                      onPressed: () {
                        log.d('Tapped settings');
                      },
                      icon: const Icon(Icons.file_upload),
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
  color: Colors.grey.shade100, // Light background color
  borderRadius: BorderRadius.circular(10.0),
  border: Border.all(color: Colors.grey.shade300),
);

final reusablePadding = EdgeInsets.all(16);

class ReusableLeftAlignedText extends StatelessWidget {
  final String text;

  const ReusableLeftAlignedText({super.key, required this.text});

  @override
  Widget build(BuildContext build) {
    return (Align(alignment: Alignment.centerLeft, child: Text(text)));
  }
}
