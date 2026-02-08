import 'package:ui_prototype/application/scanner/interfaces/scanner_device_discovery.dart';
import 'package:ui_prototype/application/scanner/dtos/discovered_port.dart';

import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';


// Interface that allows access to a list of ALL COM ports established by the 
// local machine. This means that the outgoing AND incoming ports are included
// within the list.
// 
class LibserialportDeviceDiscovery implements ScannerDeviceDiscovery {

  @override
  Future<List<DiscoveredPort>> listDevices() async {

    final ports = enumerateSerialPorts();
    List<DiscoveredPort> devices = [];

    //iterating over disovered ports
    for(int i=0; i<ports.length; i++) {
      final port = ports[i];
      var isBt = false;

      final btAddr = bluetoothAddressFromInstanceId(port.instanceId);
      final deviceName;

      //checking to see if the port is an OUTGOING bluetooth port
      if(btAddr != null && btAddr != 0) {
        deviceName = bluetoothDeviceNameFromAddress(btAddr);
        isBt = true;
      } else {
        deviceName = "";
      }

      var candidate = DiscoveredPort(deviceName as String, port.comName, port.friendlyName, isBt);
      devices.add(candidate);
    }
     
    return devices;
  }

}


//---------------- HELPER CLASSES AND FUNCTIONS --------------------------------
class SerialPortInfo {
  final String comName; // "COM4"
  final String friendlyName; // "Standard Serial over Bluetooth link (COM4)"
  final String instanceId; // PNP device instance id string

  const SerialPortInfo({
    required this.comName,
    required this.friendlyName,
    required this.instanceId,
  });
}

/// Enumerates currently-present devices in the Ports device class (GUID_DEVCLASS_PORTS),
/// returning COMx + FriendlyName + InstanceId.
///
/// This does NOT open any ports.
List<SerialPortInfo> enumerateSerialPorts({
  bool includeNonComFriendlyNames = false,
}) {
  final results = <SerialPortInfo>[];

  // GUID_DEVCLASS_PORTS = {4D36E978-E325-11CE-BFC1-08002BE10318}
  // We create a GUID and set it from the string form.
  final classGuid = calloc<GUID>();
  classGuid.ref.setGUID('{4D36E978-E325-11CE-BFC1-08002BE10318}');

  final deviceInfoSet = SetupDiGetClassDevs(
    classGuid,
    nullptr, // Enumerator
    0, // hwndParent
    DIGCF_PRESENT,
  );

  if (deviceInfoSet == INVALID_HANDLE_VALUE) {
    final err = GetLastError();
    calloc.free(classGuid);
    throw WindowsException(HRESULT_FROM_WIN32(err));
  }

  final devInfo = calloc<SP_DEVINFO_DATA>();
  devInfo.ref.cbSize = sizeOf<SP_DEVINFO_DATA>();

  try {
    for (var index = 0;
        SetupDiEnumDeviceInfo(deviceInfoSet, index, devInfo) != 0;
        index++) {
      final friendly = _getDeviceRegistryStringProperty(
            deviceInfoSet,
            devInfo,
            SPDRP_FRIENDLYNAME,
          ) ??
          _getDeviceRegistryStringProperty(
            deviceInfoSet,
            devInfo,
            SPDRP_DEVICEDESC,
          );

      if (friendly == null) continue;

      final comName = _extractComNameFromFriendly(friendly);
      if (comName == null) {
        if (!includeNonComFriendlyNames) continue;
      }

      final instanceId = _getDeviceInstanceId(deviceInfoSet, devInfo);
      if (instanceId == null) continue;

      if (comName != null) {
        results.add(SerialPortInfo(
          comName: comName,
          friendlyName: friendly,
          instanceId: instanceId,
        ));
      } else if (includeNonComFriendlyNames) {
        // Fallback: keep it, but label as unknown COM. You can remove this block if you want.
        results.add(SerialPortInfo(
          comName: 'UNKNOWN',
          friendlyName: friendly,
          instanceId: instanceId,
        ));
      }
    }

    // If SetupDiEnumDeviceInfo ends due to no more items, it sets ERROR_NO_MORE_ITEMS.
    // That's fine; we don't treat it as an error.
  } finally {
    SetupDiDestroyDeviceInfoList(deviceInfoSet);
    calloc.free(devInfo);
    calloc.free(classGuid);
  }

  return results;
}

/// Reads a REG_SZ-ish string property from SetupAPI (FriendlyName, DeviceDesc, HardwareID, etc.).
String? _getDeviceRegistryStringProperty(
  int deviceInfoSet,
  Pointer<SP_DEVINFO_DATA> devInfo,
  int property,
) {
  // Use a reasonably large buffer; if it's too small, we'll retry with the required size.
  final requiredSize = calloc<Uint32>();
  final dataType = calloc<Uint32>();

  Pointer<Uint8> buffer = nullptr;
  int bufferBytes = 0;

  try {
    // First call: ask Windows how many bytes we need (or try a default).
    bufferBytes = 1024 * 2; // 2KB
    buffer = calloc<Uint8>(bufferBytes);

    var ok = SetupDiGetDeviceRegistryProperty(
      deviceInfoSet,
      devInfo,
      property,
      dataType,
      buffer,
      bufferBytes,
      requiredSize,
    );

    if (ok == 0) {
      final err = GetLastError();
      // If buffer was too small, retry with required size.
      if (err == ERROR_INSUFFICIENT_BUFFER && requiredSize.value > 0) {
        calloc.free(buffer);
        bufferBytes = requiredSize.value;
        buffer = calloc<Uint8>(bufferBytes);

        ok = SetupDiGetDeviceRegistryProperty(
          deviceInfoSet,
          devInfo,
          property,
          dataType,
          buffer,
          bufferBytes,
          requiredSize,
        );

        if (ok == 0) return null;
      } else {
        return null;
      }
    }

    // Most of these strings are REG_SZ in UTF-16LE.
    // Convert bytes -> Utf16 string.
    final str = buffer.cast<Utf16>().toDartString();
    if (str.isEmpty) return null;
    return str;
  } finally {
    if (buffer != nullptr) calloc.free(buffer);
    calloc.free(requiredSize);
    calloc.free(dataType);
  }
}

/// Reads device instance ID (a string like "BTHENUM\\...LOCALMFG&...").
String? _getDeviceInstanceId(int deviceInfoSet, Pointer<SP_DEVINFO_DATA> devInfo) {
  final requiredSize = calloc<Uint32>();

  Pointer<Uint16> buffer = nullptr;
  int charCount = 0;

  try {
    // First try with a default size (count is in *characters*, not bytes)
    charCount = 1024;
    buffer = calloc<Uint16>(charCount);

    var ok = SetupDiGetDeviceInstanceId(
      deviceInfoSet,
      devInfo,
      buffer.cast<Utf16>(),
      charCount,
      requiredSize,
    );

    if (ok == 0) {
      final err = GetLastError();

      // If too small, retry with the required size
      if (err == ERROR_INSUFFICIENT_BUFFER && requiredSize.value > 0) {
        calloc.free(buffer);

        charCount = requiredSize.value;
        buffer = calloc<Uint16>(charCount);

        ok = SetupDiGetDeviceInstanceId(
          deviceInfoSet,
          devInfo,
          buffer.cast<Utf16>(),
          charCount,
          requiredSize,
        );

        if (ok == 0) return null;
      } else {
        return null;
      }
    }

    final id = buffer.cast<Utf16>().toDartString();
    return id.isEmpty ? null : id;
  } finally {
    if (buffer != nullptr) calloc.free(buffer);
    calloc.free(requiredSize);
  }
}


/// Extract "(COM123)" from a friendly name string.
String? _extractComNameFromFriendly(String friendlyName) {
  final match = RegExp(r'\((COM\d+)\)', caseSensitive: false).firstMatch(friendlyName);
  return match?.group(1)?.toUpperCase();
}


/// Returns the remote Bluetooth address (as an integer) if present.
/// Returns null if not a Bluetooth BTHENUM devnode.
/// Returns 0 if the instance id encodes "no remote address" (commonly incoming SPP port).
int? bluetoothAddressFromInstanceId(String instanceId) {
  if (!instanceId.startsWith('BTHENUM')) return null;

  final lastAmp = instanceId.lastIndexOf('&');
  final lastUnderscore = instanceId.lastIndexOf('_');
  if (lastAmp < 0 || lastUnderscore < 0 || lastUnderscore <= lastAmp + 1) {
    return null;
  }

  final hex = instanceId.substring(lastAmp + 1, lastUnderscore);
  return int.tryParse(hex, radix: 16);
}

//====================== Bluetooth Device Name Mapping =========================
// -----------------------------
// Bluetooth classic Win32 API: address -> device name
// -----------------------------

final DynamicLibrary _bthprops = DynamicLibrary.open('bthprops.cpl');

typedef _BluetoothFindFirstRadioC = IntPtr Function(
  Pointer<BLUETOOTH_FIND_RADIO_PARAMS> pParams,
  Pointer<IntPtr> phRadio,
);
typedef _BluetoothFindFirstRadioDart = int Function(
  Pointer<BLUETOOTH_FIND_RADIO_PARAMS> pParams,
  Pointer<IntPtr> phRadio,
);


typedef _BluetoothFindNextRadioC = Int32 Function(
  IntPtr hFind,
  Pointer<IntPtr> phRadio,
);
typedef _BluetoothFindNextRadioDart = int Function(
  int hFind,
  Pointer<IntPtr> phRadio,
);

typedef _BluetoothFindRadioCloseC = Int32 Function(IntPtr hFind);
typedef _BluetoothFindRadioCloseDart = int Function(int hFind);

typedef _BluetoothGetDeviceInfoC = Uint32 Function(
  IntPtr hRadio,
  Pointer<BLUETOOTH_DEVICE_INFO> pDeviceInfo,
);
typedef _BluetoothGetDeviceInfoDart = int Function(
  int hRadio,
  Pointer<BLUETOOTH_DEVICE_INFO> pDeviceInfo,
);


final _BluetoothFindFirstRadio =
    _bthprops.lookupFunction<_BluetoothFindFirstRadioC, _BluetoothFindFirstRadioDart>(
      'BluetoothFindFirstRadio',
    );
final _BluetoothFindNextRadio =
    _bthprops.lookupFunction<_BluetoothFindNextRadioC, _BluetoothFindNextRadioDart>(
      'BluetoothFindNextRadio',
    );
final _BluetoothFindRadioClose =
    _bthprops.lookupFunction<_BluetoothFindRadioCloseC, _BluetoothFindRadioCloseDart>(
      'BluetoothFindRadioClose',
    );
final _BluetoothGetDeviceInfo =
    _bthprops.lookupFunction<_BluetoothGetDeviceInfoC, _BluetoothGetDeviceInfoDart>(
      'BluetoothGetDeviceInfo',
    );

final class BLUETOOTH_FIND_RADIO_PARAMS extends Struct {
  @Uint32()
  external int dwSize;
}

final class BLUETOOTH_ADDRESS_U extends Union {
  @Uint64()
  external int ullLong;
}

final class BLUETOOTH_ADDRESS extends Struct {
  external BLUETOOTH_ADDRESS_U u;
}

final class SYSTEMTIME extends Struct {
  @Uint16()
  external int wYear;
  @Uint16()
  external int wMonth;
  @Uint16()
  external int wDayOfWeek;
  @Uint16()
  external int wDay;
  @Uint16()
  external int wHour;
  @Uint16()
  external int wMinute;
  @Uint16()
  external int wSecond;
  @Uint16()
  external int wMilliseconds;
}

final class BLUETOOTH_DEVICE_INFO extends Struct {
  @Uint32()
  external int dwSize;

  external BLUETOOTH_ADDRESS Address;

  @Uint32()
  external int ulClassofDevice;

  @Int32()
  external int fConnected;
  @Int32()
  external int fRemembered;
  @Int32()
  external int fAuthenticated;

  external SYSTEMTIME stLastSeen;
  external SYSTEMTIME stLastUsed;

  // WCHAR szName[248]
  @Array(248)
  external Array<Uint16> szName;
}



String _wcharArrayToString(Array<Uint16> arr, int maxLen) {
  final codeUnits = <int>[];
  for (var i = 0; i < maxLen; i++) {
    final v = arr[i];
    if (v == 0) break;
    codeUnits.add(v);
  }
  return String.fromCharCodes(codeUnits);
}


/// Returns the Windows Bluetooth device name for a Bluetooth address (ULL) if known.
/// - Does NOT connect to the device.
/// - Works when the device is remembered/paired/known to Windows.
/// - Returns null if no radio, Bluetooth off, or device not found.
String? bluetoothDeviceNameFromAddress(int btAddressUll) {
  if (!Platform.isWindows) return null;

  final pParams = calloc<BLUETOOTH_FIND_RADIO_PARAMS>()..ref.dwSize = sizeOf<BLUETOOTH_FIND_RADIO_PARAMS>();
  final phRadio = calloc<IntPtr>();

  int hFind = 0;
  try {
    hFind = _BluetoothFindFirstRadio(pParams, phRadio);
    if (hFind == 0) {
      // No Bluetooth radio found / Bluetooth off
      return null;
    }

    while (true) {
      final hRadio = phRadio.value;
      if (hRadio != 0) {
        final info = calloc<BLUETOOTH_DEVICE_INFO>();
        try {
          info.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();
          info.ref.Address.u.ullLong = btAddressUll;

          final result = _BluetoothGetDeviceInfo(hRadio, info);
          if (result == ERROR_SUCCESS) {
            final name = _wcharArrayToString(info.ref.szName, 248);
            if (name.isNotEmpty) return name;
          }
        } finally {
          calloc.free(info);
        }

        // Close the radio handle (it's a HANDLE)
        CloseHandle(hRadio);
      }

      // Next radio (most PCs have only one)
      final ok = _BluetoothFindNextRadio(hFind, phRadio);
      if (ok == 0) break;
    }

    return null;
  } finally {
    if (hFind != 0) _BluetoothFindRadioClose(hFind);
    calloc.free(phRadio);
    calloc.free(pParams);
  }
}
