import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/providers/sound_provider.dart';

//constants that deal with spacing for the master toggle 
const double kSoundPreviewButtonSpacing = 93.0;
const double kSoundToggleSpacing = 16.0;

//widget for the master toggle row in settings
class MasterSoundToggleRow extends ConsumerWidget {
  const MasterSoundToggleRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSoundsEnabled = ref.watch(allSoundsEnabledProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Enable All Sounds',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Off',
                style: TextStyle(
                  color: allSoundsEnabled ? Colors.grey : Colors.black,
                  fontWeight: allSoundsEnabled
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: allSoundsEnabled,
                onChanged: (value) {
                  ref.read(soundSettingsProvider.notifier).setAllEnabled(value);
                },
              ),
              const SizedBox(width: 8),
              Text(
                'On',
                style: TextStyle(
                  color: allSoundsEnabled ? Colors.black : Colors.grey,
                  fontWeight: allSoundsEnabled
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              
              const SizedBox(width: kSoundToggleSpacing),

              // spacing 
              const SizedBox(width: kSoundPreviewButtonSpacing),
            ],
          ),
        ],
      ),
    );
  }
}