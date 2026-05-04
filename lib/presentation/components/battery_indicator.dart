//this file has the the UI for the battery and its functions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/domain/enums/battery_state.dart';
import 'package:crab_cakes/infrastructure/providers/battery_provider.dart';

//used consumerWidget so it can listen to riverpod providers
class BatteryIndicator extends ConsumerWidget {
  const BatteryIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //UI updates when battery changes
    final batteryLevel = ref.watch(batteryLevelProvider);
    final batteryState = ref.watch(batteryStateProvider);

    //async battery level stream
    return batteryLevel.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (level) {
        //check if battery is charging
        return batteryState.when(
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
          data: (state) {
            final isCharging = state == BatteryState.charging || state == BatteryState.full;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomBatteryWidget(
                  level: level,
                  isCharging: isCharging,
                ),
                const SizedBox(width: 6),
                Text(
                  "$level%",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

//this widget is responsable for drawing the battery icon
class CustomBatteryWidget extends StatelessWidget {
  final int level;
  final bool isCharging;

  const CustomBatteryWidget({
    super.key,
    required this.level,
    required this.isCharging,
  });

  @override
  //change colors based on battery percentage
  Widget build(BuildContext context) {
    Color batteryColor;

    if (level >= 60) {
      batteryColor = Colors.green;
    } else if (level >= 30) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = Colors.red;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Battery outline
            Container(
              width: 32,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // make sure battery goes down or up smoothly 
            Positioned(
              left: 2,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: (28 * (level / 100)).clamp(0, 28),
                height: 12,
                decoration: BoxDecoration(
                  color: batteryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
        // create a charging bolt when user is charging their device
        if (isCharging)
          const Positioned(
            top: 1,
            left: 9,
            child: Icon(
              Icons.bolt,
              size: 14,
              color: Colors.black,
            ),
          ),
          
      ],
    );
  }
}