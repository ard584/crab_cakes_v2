import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_prototype/infrastructure/providers/external_backup_provider.dart';

// This file specifically handles any startup orchestration that needs to happen 
// the app. 
// Note: Right now it handles only the backup selection. DELETE THIS LINE IF ANYTHING ELSE IS ADDED

final startupProvider = FutureProvider<void>((ref) async {
  await ref.read(autoSelectBackupTargetsProvider).execute();
}); 