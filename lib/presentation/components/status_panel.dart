//UI components that holds the status of important comonents currently its just the battery 
//but if needed more can be added

import 'package:flutter/material.dart';
import 'battery_indicator.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "STATUS",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 12),
          // Row displaying status items (more items can be added below)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: const [
                Text(
                  "Battery",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 12),
                BatteryIndicator(),
              ],
            )
          ),

        ],
      ),
    );
  }
}