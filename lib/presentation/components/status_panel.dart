//UI components that holds the status of important comonents currently its just the battery 
//but if needed more can be added

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'battery_indicator.dart';

import 'package:crab_cakes/infrastructure/providers/pit_readers_providers.dart';
import 'package:crab_cakes/infrastructure/providers/external_backup_provider.dart';
import 'package:crab_cakes/infrastructure/providers/settings_provider.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: 520,
      ),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: BatteryStatusRow(),
          ),
          SizedBox(height: 8),
          ScannerStatusPanel(),
          SizedBox(height: 10),
          Divider(height: 1),
          SizedBox(height: 10),
          BackupStatusPanel(),
        ],
      ),
    );
  }
}

class BatteryStatusRow extends StatelessWidget {
  const BatteryStatusRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      // Row displaying status items (more items can be added below)
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: const [
          Flexible(
            child: Text(
              "Battery",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13),
            ),
          ),
          SizedBox(width: 8),
          BatteryIndicator(),
        ],
      ),
    );
  }
}

class ScannerStatusPanel extends ConsumerWidget {
  const ScannerStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pitConnectionState = ref.watch(pitConnectionControllerProvider);
    final liveStatusAsync = ref.watch(scannerConnectionStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scanner Status',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),

        if (pitConnectionState.isConnecting)
          const _StatusLine(
            isWarning: false,
            label: 'Bluetooth scanner',
            value: 'Connecting...',
            helpTitle: 'Bluetooth scanner',
            helpText:
                'The app is currently trying to connect to the selected PIT tag scanner.',
          )
        else if (!pitConnectionState.isConnected)
          const _StatusLine(
            isWarning: true,
            label: 'Bluetooth scanner',
            value: 'Not connected',
            helpTitle: 'Bluetooth scanner',
            helpText:
                'The PIT tag scanner is not connected. Records can still be entered manually, but scan data will not automatically populate the configured scanner field.',
          )
        else
          liveStatusAsync.when(
            data: (isStillConnected) {
              final connectedDeviceId =
                  pitConnectionState.connectedDeviceId ?? 'Unknown device';

              return _StatusLine(
                isWarning: !isStillConnected,
                label: 'Bluetooth scanner',
                value: isStillConnected
                    ? 'Connected: $connectedDeviceId'
                    : 'Connection may be stale',
                helpTitle: 'Bluetooth scanner',
                helpText:
                    'This status reflects the scanner connection reported by the app and scanner adapter. If the scanner is turned off or the Bluetooth serial connection becomes stale, the app may only detect that once the serial reader reports an error or the device is disconnected through the app.',
              );
            },
            loading: () => const Text('Bluetooth scanner: checking...'),
            error: (error, stack) {
              return const _StatusLine(
                isWarning: true,
                label: 'Bluetooth scanner',
                value: 'Error checking status',
                helpTitle: 'Bluetooth scanner',
                helpText:
                    'The app could not confirm the scanner connection status. Records can still be saved manually, but scanner input may not be available.',
              );
            },
          ),
      ],
    );
  }
}


class BackupStatusPanel extends ConsumerWidget {
  const BackupStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(projectSettingsProvider);
    final targetsAsync = ref.watch(connectedSelectedBackupTargetsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backup Status',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),

        targetsAsync.when(
          data: (targets) {
            final hasTargets = targets.isNotEmpty;

            return _StatusLine(
              isWarning: !hasTargets,
              label: 'Backup drives',
              value: hasTargets
                  ? targets.map((target) => target.drivePath).join(', ')
                  : 'No selected drives connected',
              helpTitle: 'Backup drives',
              helpText:
                  'Selected backup drives are the external drives where the app copies this project database after each saved record. '
                  'If no selected drives are connected, records are still saved locally, but no external backup is created.',
            );
          },
          loading: () => const Text('Backup drives: checking...'),
          error: (error, stack) {
            return _StatusLine(
              isWarning: true,
              label: 'Backup drives',
              value: 'Error checking drives',
              helpTitle: 'Backup drives',
              helpText:
                  'The app could not check the selected backup drives. Records may still save locally, but external backup status could not be confirmed.',
            );
          },
        ),

        const SizedBox(height: 6),

        settingsAsync.when(
          data: (settings) {
            final baseTable = settings.export.baseTable;
            final hasBaseTable = baseTable != null;

            return _StatusLine(
              isWarning: !hasBaseTable,
              label: 'Export base table',
              value: hasBaseTable
                  ? baseTable
                  : 'No base table selected',
              helpTitle: 'Export base table',
              helpText:
                  'The base table controls the text export created during backups. Each exported row is based on this table, with related data included according to the project schema. '
                  'If no base table is selected, the database backup is still created, but export/data.txt is skipped.',
            );
          },
          loading: () => const Text('Export base table: loading...'),
          error: (error, stack) {
            return _StatusLine(
              isWarning: true,
              label: 'Export base table',
              value: 'Error loading settings',
              helpTitle: 'Export base table',
              helpText:
                  'The app could not load the saved export base table. Database backups may still work, but text export settings could not be confirmed.',
            );
          },
        ),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final bool isWarning;
  final String label;
  final String value;
  final String helpTitle;
  final String helpText;

  const _StatusLine({
    required this.isWarning,
    required this.label,
    required this.value,
    required this.helpTitle,
    required this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(color: color),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'What does this mean?',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: Text(helpTitle),
                    content: Text(helpText),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}