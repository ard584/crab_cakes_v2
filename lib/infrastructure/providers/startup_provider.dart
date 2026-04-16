import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/external_backup_provider.dart';
import 'package:flutter/foundation.dart';

// This file specifically handles any startup orchestration that needs to happen 
// the app. 
// Note: Right now it handles only the backup selection. DELETE THIS LINE IF ANYTHING ELSE IS ADDED

final startupProvider = FutureProvider<void>((ref) async {

  try {
    await ref.read(autoSelectBackupTargetsProvider).execute();
  } on UnsupportedError catch (e) {
    // This error is expected on both Mac and Linux, so we continue letting the 
    // UI load, we just let the console know for now.
    debugPrint("WARNING: BACKUP IS NOT SUPPORTED ON THIS PLATFORM!");
    debugPrint("Error: $e");
  } catch (e, stackTrace) {
    // this is a REAL startup, so we rethrow to let the caller know
    // UI should still throw an error here

    debugPrint("Error: $e");
    debugPrint("StackTrace: $stackTrace");
    rethrow;
  }


  
}); 