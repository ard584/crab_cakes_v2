import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crab_cakes/presentation/components/usb_backups_section.dart';
import 'package:crab_cakes/presentation/components/scanner_target_section.dart';
import 'package:crab_cakes/domain/enums/app_sound.dart';
import 'package:crab_cakes/presentation/components/sound_setting_row.dart';
import 'package:crab_cakes/presentation/components/master_sound_toggle_row.dart';

//importing the specific scanner connection component
import 'package:crab_cakes/presentation/components/pit_reader_section.dart';

// import your settings providers file
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';

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

              const ReusableLeftAlignedText(text: 'Project Configuration Export'),
              Container(
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
              //START OF SOUND SYSTEM
              ReusableLeftAlignedText(text: 'Sound Settings'),
              const MasterSoundToggleRow(),
              const SizedBox(height: 8),

              //print the sounds
              ...AppSound.values.map(
                (sound) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SoundSettingRow(
                    sound: sound,
                    label: sound.label,
                  ),
                ),
              ),

            ],
          ),
      ),
    ));
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
  Widget build(BuildContext build) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}