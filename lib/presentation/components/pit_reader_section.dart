import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/presentation/components/project_widget.dart';

import 'package:crab_cakes/infrastructure/providers/pit_readers_providers.dart';
import 'package:crab_cakes/presentation/screens/project_creation.dart';


class PitReadersSection extends ConsumerStatefulWidget {
  const PitReadersSection({super.key});

  @override
  ConsumerState<PitReadersSection> createState() => _PitReadersSectionState();
}

class _PitReadersSectionState extends ConsumerState<PitReadersSection> {
  String? _lastConnectedDeviceId;

  @override
  void initState() {
    super.initState();

    // Clear old connection errors when this section is opened/rebuilt into the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(pitConnectionControllerProvider.notifier).clearError();

      // If the app still has a confirmed scanner connection, restore the dropdown
      // selection to that device when returning to this section.
      //
      // This keeps the button state consistent:
      // - selected connected device => Disconnect
      // - selected different device => Connect
      final conn = ref.read(pitConnectionControllerProvider);

      if (conn.connectedDeviceId != null) {
        ref.read(selectedDeviceIdProvider.notifier).state = conn.connectedDeviceId;
      }
    });
  }

  String _formatConnectionError(Object? error) {
    if (error == null) {
      return '';
    }

    final text = error.toString();

    // Makes Exception('message') display a little cleaner in the UI.
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }

    return text;
  }

  void _showConnectionErrorDialog(BuildContext context, Object? error) {
    final message = _formatConnectionError(error);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scanner Connection Failed'),
          content: Text(
            message.isEmpty
              ? 'The scanner could not be connected. Make sure the reader is powered on, paired with this computer, and using the correct COM port.'
              : message,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(discoveredDevicesProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final showAll = ref.watch(showAllDevicesProvider);
    final conn = ref.watch(pitConnectionControllerProvider);

    final hasConnectionError = conn.error != null;
    final connectionErrorMessage = _formatConnectionError(conn.error);

    final connectedDeviceId = conn.connectedDeviceId;

    // Use one effective dropdown value for both the dropdown and button logic.
    //
    // If selectedId is missing for a moment while this section is restoring,
    // fall back to the currently connected device.
    final effectiveSelectedDeviceId = selectedId ?? connectedDeviceId;

    // Tracks whether the dropdown's currently selected device is the scanner
    // that the app currently confirms as connected.
    //
    // This keeps the button state tied to the selected dropdown option:
    // - selected connected device => Disconnect
    // - selected different device => Connect
    final selectedDeviceIsConnected =
      conn.isConnected &&
      connectedDeviceId != null &&
      effectiveSelectedDeviceId == connectedDeviceId;

    // Keep the last confirmed connected device only as historical memory.
    //
    // Do not use this to display "Connected to ..." because it can make the UI
    // claim a connection exists after the real connection state has reset.
    if (connectedDeviceId != null) {
      _lastConnectedDeviceId = connectedDeviceId;
    }

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

                    final effectiveSelectionStillExists =
                      effectiveSelectedDeviceId != null &&
                      devices.any((device) => device.port == effectiveSelectedDeviceId);

                    final value = effectiveSelectionStillExists
                      ? effectiveSelectedDeviceId
                      : devices.first.port;

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
                        onChanged: conn.isConnecting
                          ? null
                          : (newId) {
                              if (newId == null) return;

                              ref.read(selectedDeviceIdProvider.notifier).state = newId;

                              // Clear old connection error when the user picks another device.
                              //
                              // NOTE: This intentionally does not clear the last displayed
                              // connected device. The dropdown selection represents the next
                              // target device, while the status text represents the last
                              // confirmed successful scanner connection.
                              ref.read(pitConnectionControllerProvider.notifier).clearError();
                            },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                width: 120,
                child: FilledButton(
                  onPressed: conn.isConnecting
                      ? null
                      : () async {
                          final controller =
                              ref.read(pitConnectionControllerProvider.notifier);

                          if (selectedDeviceIsConnected) {
                            await controller.disconnect();

                            if (mounted) {
                              setState(() {
                                _lastConnectedDeviceId = null;
                              });
                            }
                          } else {
                            await controller.connectSelected();

                            final latestConn =
                              ref.read(pitConnectionControllerProvider);

                            if (mounted && latestConn.connectedDeviceId != null) {
                              setState(() {
                                _lastConnectedDeviceId =
                                  latestConn.connectedDeviceId;
                              });
                            }
                          }
                        },
                  child: conn.isConnecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        selectedDeviceIsConnected ? 'Disconnect' : 'Connect',
                      ),
                ),
              ),

              IconButton(
                tooltip: 'Refresh devices',
                onPressed: conn.isConnecting
                  ? null
                  : () {
                      ref.read(pitConnectionControllerProvider.notifier).clearError();
                      ref.invalidate(discoveredDevicesProvider);
                    },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: showAll,
                onChanged: conn.isConnecting
                  ? null
                  : (v) {
                      ref.read(showAllDevicesProvider.notifier).state = v ?? false;

                      // Clear old connection error when device discovery options change.
                      ref.read(pitConnectionControllerProvider.notifier).clearError();
                    },
              ),
              const Text('Show all'),
              if (hasConnectionError) ...[
                const Spacer(),
                IconButton(
                  tooltip: 'Show connection error',
                  onPressed: () => _showConnectionErrorDialog(context, conn.error),
                  icon: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              if (conn.isConnecting) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('Connecting to scanner...'),
              ] else if (conn.isConnected && connectedDeviceId != null && !hasConnectionError) ...[
                const Icon(Icons.check_circle_outline, size: 18),
                const SizedBox(width: 8),
                Text('Connected to $connectedDeviceId'),
              ] else if (hasConnectionError) ...[
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connectionErrorMessage.isEmpty
                      ? 'Could not connect to scanner.'
                      : connectionErrorMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => _showConnectionErrorDialog(context, conn.error),
                  child: const Text('Details'),
                ),
              ] else if (_lastConnectedDeviceId != null) ...[
                const Icon(Icons.bluetooth_disabled, size: 18),
                const SizedBox(width: 8),
                Text('Scanner disconnected. Last connected: $_lastConnectedDeviceId'),
              ] else ...[
                const Icon(Icons.bluetooth_disabled, size: 18),
                const SizedBox(width: 8),
                const Text('Scanner disconnected'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}