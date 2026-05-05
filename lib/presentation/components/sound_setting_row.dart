import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/domain/enums/app_sound.dart';
import 'package:crab_cakes/infrastructure/providers/sound_provider.dart';

//front end of how the sound system will look in the settings
class SoundSettingRow extends ConsumerWidget {
  //shows the sound name, on/off switch and a play button for preview 
  //and its in a row widget
  const SoundSettingRow
  ({
    super.key,
    required this.sound,
    required this.label,
  });

  final AppSound sound;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) 
  {
    final enabled = ref.watch(soundEnabledProvider(sound));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Off',
                style: TextStyle(
                  color: enabled ? Colors.grey : Colors.black,
                  fontWeight: enabled ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: enabled,
                onChanged: (value) {
                  ref.read(soundSettingsProvider.notifier).setEnabled(sound, value);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'On',
                style: TextStyle(
                  color: enabled ? Colors.black : Colors.grey,
                  fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(soundServiceProvider).preview(sound);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}