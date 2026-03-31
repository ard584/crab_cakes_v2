import 'dart:ffi';

import 'package:ui_prototype/application/backup/dtos/backup_target.dart';
import 'package:ui_prototype/application/backup/interfaces/drive_discovery.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';


class Win32DriveDiscovery implements DriveDiscovery{

  @override
  Future<List<BackupTarget>> discover() async {
    //get the list of connected drives (USB, SD, etc)
    List<String> candidates = _getLogicalDrives();
    List<BackupTarget> targetList = [];

    //filter by drives that can be written to 
    final List<String> filteredDrives = _filterByDriveType(candidates, DRIVE_REMOVABLE);

    //TODO: try to write, ensure drive is writable


    //make objects and return to the caller
    for(int i = 0; i<filteredDrives.length; i++) {
      final targetId = _getVolumeGuid(filteredDrives[i]) ?? filteredDrives[i];

      final newTarget = BackupTarget(targetId, filteredDrives[i]);

      targetList.add(newTarget);
    }
    //temporary stub return 
    return targetList;
  }
//======================= HELPER METHODS =====================================

  //Returns a list of detected drives on the device. It is important to note that
  // at this point, the list can consist of all USB devices connected to the
  // device, and not necessarily JUST removable storage media.  
  List<String> _getLogicalDrives() {
  const bufferLength = 256; // chars, not bytes
  final buffer = calloc<Uint16>(bufferLength);

  try {
    final written = GetLogicalDriveStrings(bufferLength, buffer.cast());
    if (written == 0) return [];

    // Multi-string: "C:\0D:\0E:\0\0"
    final units = buffer.asTypedList(written);

    final drives = <String>[];
    var start = 0;

    for (var i = 0; i < units.length; i++) {
      if (units[i] == 0) {
        if (i == start) break; // double-null terminator => done
        drives.add(String.fromCharCodes(units.sublist(start, i)));
        start = i + 1;
      }
    }
    return drives;
  } finally {
    calloc.free(buffer);
  }
}

//  Mutates the 'drives' parameter to only include drives of the specified 
//  'targetType'. This function can be used to filter the drive list for specific
//  types of drives
List<String> _filterByDriveType(List<String> drives, int targetType) {
  return drives.where((root) {
    final rootPtr = root.toNativeUtf16();
    try {
      return GetDriveType(rootPtr) == targetType;
    } finally {
      calloc.free(rootPtr);
    }
  }).toList();
}

//  Returns the Globally Unique Identifier of the specified drive. If no such 
//  identifier is found, it simply stores the drive path as the id. 
// 'root' must be in the format ex: 'E:\\'
String? _getVolumeGuid(String root) {
  // root must be like "E:\\"
  final rootPtr = root.toNativeUtf16();

  // Volume GUID path strings can be longer; MAX_PATH is usually enough, but give slack.
  const bufLen = 512;
  final buf = calloc<Uint16>(bufLen);

  try {
    final ok = GetVolumeNameForVolumeMountPoint(
      rootPtr,
      buf.cast(),
      bufLen,
    );

    if (ok == 0) return null;
    return buf.cast<Utf16>().toDartString();
  } finally {
    calloc.free(rootPtr);
    calloc.free(buf);
  }
}

}

