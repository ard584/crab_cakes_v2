import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/presentation/components/project_widget.dart';

import 'package:ui_prototype/infrastructure/providers/pit_readers_providers.dart';
import 'package:ui_prototype/presentation/screens/project_creation.dart';


class PitReadersSection extends ConsumerWidget {
  const PitReadersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final showAll = ref.watch(showAllDevicesProvider);
    final conn = ref.watch(pitConnectionControllerProvider);

    return Container(
      decoration: reusableBoxDecoration,
      padding: reusablePadding,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bluetooth_connected),
              const SizedBox(width: 8),

              Expanded(
                child: devicesAsync.when(
                  loading: () => const Text('Scanning...'),
                  error: (e, _) => Text('Error: $e'),
                  data: (devices) {
                    if (devices.isEmpty) return const Text('No devices found');

                    final value = selectedId ?? devices.first.port;

                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: value,
                        items: devices.map((d) {
                          return DropdownMenuItem(
                            value: d.port,
                            child: Text(d.displayName, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          ref.read(selectedDeviceIdProvider.notifier).state = newId;
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              FilledButton(
                onPressed: conn.isConnecting
                    ? null
                    : () async {
                        final controller =
                            ref.read(pitConnectionControllerProvider.notifier);

                        if (conn.isConnected) {
                          await controller.disconnect();
                        } else {
                          await controller.connectSelected();
                        }
                      },
                child: Text(
                  conn.isConnected ? 'Disconnect' : 'Connect',
                ),
              ),

              IconButton(
                tooltip: 'Refresh devices',
                onPressed: () => ref.invalidate(discoveredDevicesProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: showAll,
                onChanged: (v) {
                  ref.read(showAllDevicesProvider.notifier).state = v ?? false;
                },
              ),
              const Text('Show all'),
              if (conn.error != null) ...[
                const Spacer(),
                const Icon(Icons.error_outline),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
