import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

//importing use cases
import 'package:ui_prototype/application/scanner/usecases/connect_scanner.dart';
import 'package:ui_prototype/application/scanner/usecases/disconnect_scanner.dart';
import 'package:ui_prototype/application/scanner/usecases/list_devices.dart';

//importing interfaces 
import 'package:ui_prototype/application/scanner/interfaces/scanner_connector.dart';
import 'package:ui_prototype/application/scanner/interfaces/scanner_device_discovery.dart';

//importing DTO
import 'package:ui_prototype/application/scanner/dtos/discovered_port.dart';

//importing concrete infrastructure implementations
import 'package:ui_prototype/infrastructure/scanner/libserialport_adapter.dart';
import 'package:ui_prototype/infrastructure/scanner/libserialport_device_discovery.dart';

//------------------------------------------------------------------------------



//Wiring INFRASTRUCTURE providers
final scannerDiscoveryProvider = Provider<ScannerDeviceDiscovery>((ref) {
  // Construct the concrete discovery implementation
  return LibserialportDeviceDiscovery(/* any constructor args */);
});

final scannerConnectorProvider = Provider<ScannerConnector>((ref) {
  // Construct the concrete connector implementation
  return LibserialportAdapter(/* any constructor args */);
});


// Wiring USE CASE providers (which read the infra providers)
final listDevicesUsecaseProvider = Provider<ListDevices>((ref) {
  final discovery = ref.read(scannerDiscoveryProvider);
  return ListDevices(discovery);
});

final connectScannerUsecaseProvider = Provider<ConnectScanner>((ref) {
  final connector = ref.read(scannerConnectorProvider);
  return ConnectScanner(connector);
});

final disconnectScannerUsecaseProvider = Provider<DisconnectScanner>((ref) {
  final connector = ref.read(scannerConnectorProvider);
  return DisconnectScanner(connector);
});

//-------------------- Wiring Complete -----------------------------------------


//using use case providers for feature providers
final showAllDevicesProvider = StateProvider<bool>((ref) => false);

final discoveredDevicesProvider = FutureProvider<List<DiscoveredPort>>((ref) async {
  final showAll = ref.watch(showAllDevicesProvider);
  final listDevices = ref.read(listDevicesUsecaseProvider);

  // IMPORTANT: adjust this line to match your use case API
  final devices = showAll
    ? await listDevices.all()
    : await listDevices.likely();
  
  devices.sort((a, b) => a.displayName.compareTo(b.displayName));

  // auto-select first if none selected
  final selected = ref.read(selectedDeviceIdProvider);
  if (selected == null && devices.isNotEmpty) {
    ref.read(selectedDeviceIdProvider.notifier).state = devices.first.port; 
  }

  return devices;
});


//Defining Connection State
class PitConnectionState {
  final bool isConnecting;
  final String? connectedDeviceId; // null => not connected
  final Object? error;

  const PitConnectionState({
    this.isConnecting = false,
    this.connectedDeviceId,
    this.error,
  });

  bool get isConnected => connectedDeviceId != null;

  PitConnectionState copyWith({
    bool? isConnecting,
    String? connectedDeviceId,
    Object? error,
  }) {
    return PitConnectionState(
      isConnecting: isConnecting ?? this.isConnecting,
      connectedDeviceId: connectedDeviceId,
      error: error,
    );
  }

  static const disconnected = PitConnectionState();
}


//Using the Use Cases to control UI

// Store selected device id (or address)
final selectedDeviceIdProvider = StateProvider<String?>((ref) => null);

class PitConnectionController extends StateNotifier<PitConnectionState> {
  PitConnectionController(this._ref) : super(PitConnectionState.disconnected);

  final Ref _ref;

  Future<void> connectSelected() async {
    final selectedId = _ref.read(selectedDeviceIdProvider); 
    if (selectedId == null) {
      state = state.copyWith(error: Exception('No device selected'));
      return;
    }

    // If already connected to something, disconnect first (optional policy)
    if (state.isConnected) {
      await disconnect();
    }

    state = state.copyWith(isConnecting: true, error: null);

    try {
      final connect = _ref.read(connectScannerUsecaseProvider);

      // Adjust to your use case API:
      // await connect(deviceId: selectedId);
      await connect.execute(selectedId);

      state = PitConnectionState(
        isConnecting: false,
        connectedDeviceId: selectedId,
        error: null,
      );
    } catch (e) {
      state = PitConnectionState(
        isConnecting: false,
        connectedDeviceId: null,
        error: e,
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isConnecting: true, error: null);
    try {
      final disconnect = _ref.read(disconnectScannerUsecaseProvider);

      // Adjust to your use case API:
      await disconnect.execute();

      state = PitConnectionState.disconnected;
    } catch (e) {
      state = state.copyWith(isConnecting: false, error: e);
      rethrow;
    }
  }
}


//adding Controller Provider
final pitConnectionControllerProvider =
    StateNotifierProvider<PitConnectionController, PitConnectionState>((ref) {
  return PitConnectionController(ref);
});


// Selected Device Provider
final selectedDeviceProvider = Provider<DiscoveredPort?>((ref) {
  final selectedId = ref.watch(selectedDeviceIdProvider);
  final devicesAsync = ref.watch(discoveredDevicesProvider);

  return devicesAsync.maybeWhen(
    data: (devices) {
      if (devices.isEmpty) return null;
      // pick selected, or default to first
      return devices.firstWhere(
        (d) => d.port == selectedId, 
        orElse: () => devices.first,
      );
    },
    orElse: () => null,
  );
});




