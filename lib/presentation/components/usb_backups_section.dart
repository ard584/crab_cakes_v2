import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:ui_prototype/presentation/utils/logger.dart';

// Providers/use-cases wiring
import 'package:ui_prototype/infrastructure/providers/external_backup_provider.dart';
import 'package:ui_prototype/application/backup/dtos/backup_target.dart';

final _selectedDriveIdProvider = StateProvider<String?>((ref) => null);

class UsbBackupDrivesSection extends ConsumerStatefulWidget {
  const UsbBackupDrivesSection({super.key});

  @override
  ConsumerState<UsbBackupDrivesSection> createState() =>
      _UsbBackupDrivesSectionState();
}

class _UsbBackupDrivesSectionState extends ConsumerState<UsbBackupDrivesSection> {
  late Future<List<BackupTarget>> _drivesFuture;

  @override
  void initState() {
    super.initState();
    _drivesFuture = ref.read(discoverDevicesProvider).execute();
  }

  void _refreshDrives() {
    setState(() {
      _drivesFuture = ref.read(discoverDevicesProvider).execute();
    });
  }

  Future<void> _refreshSelectedPool() async {
    // Fix A: force FutureBuilders to re-run by rebuilding the widget tree
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(_selectedDriveIdProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LeftAlignedHeader('USB Backup Locations'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<BackupTarget>>(
            future: _drivesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Detecting drives...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Row(
                  children: [
                    const Icon(Icons.error_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Drive detection failed: ${snapshot.error}'),
                    ),
                    IconButton(
                      tooltip: 'Retry',
                      onPressed: _refreshDrives,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );
              }

              final drives = snapshot.data ?? [];
              if (drives.isEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.usb_off),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('No removable drives detected.')),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _refreshDrives,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select a drive',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Refresh drive list',
                        onPressed: _refreshDrives,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    items: drives.map((d) {
                      final title = d.drivePath;
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text(title, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      ref.read(_selectedDriveIdProvider.notifier).state = val;
                    },
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add USB Drive'),
                      onPressed: selectedId == null
                          ? null
                          : () async {
                              try {
                                final current =
                                    await ref.read(getBackupTargetsProvider).execute();

                                final updated = {...current, selectedId};

                                // SelectDrives uses `call`, so invoke it like a function
                                await ref.read(selectDrivesProvider)(updated);

                                // Fix A: force UI refresh so selected list updates
                                await _refreshSelectedPool();

                                log.d('Added drive id=$selectedId');

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Drive added to backup pool.'),
                                  ),
                                );
                              } catch (e) {
                                log.e('Failed to add drive: $e');
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to add drive: $e')),
                                );
                              }
                            },
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SelectedBackupPool(
                    drives: drives,
                    onChanged: _refreshSelectedPool, // Fix A hook for removals
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedBackupPool extends ConsumerWidget {
  const _SelectedBackupPool({
    required this.drives,
    required this.onChanged,
  });

  final List<BackupTarget> drives;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Set<String>>(
      future: ref.read(getBackupTargetsProvider).execute(),
      builder: (context, snapshot) {
        final selectedIds = snapshot.data ?? const <String>{};

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading selected backup drives...');
        }

        if (selectedIds.isEmpty) {
          return const Text('No drives selected for backup yet.');
        }

        final selectedDrives =
            drives.where((d) => selectedIds.contains(d.id)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selected drives:'),
            const SizedBox(height: 8),
            ...selectedDrives.map((d) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.usb),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d.drivePath)),
                    IconButton(
                      tooltip: 'Remove from backup pool',
                      icon: const Icon(Icons.eject),
                      onPressed: () async {
                        try {
                          final current =
                              await ref.read(getBackupTargetsProvider).execute();
                          final updated = {...current}..remove(d.id);

                          await ref.read(selectDrivesProvider)(updated);

                          // Fix A: force UI refresh so list updates
                          await onChanged();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Drive removed.')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to remove drive: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _LeftAlignedHeader extends StatelessWidget {
  const _LeftAlignedHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text),
    );
  }
}
