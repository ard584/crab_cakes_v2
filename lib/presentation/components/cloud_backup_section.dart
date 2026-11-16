import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:crab_cakes/infrastructure/providers/active_database_connection_provider.dart';
import 'package:crab_cakes/infrastructure/backup/sqlite_db_backup_writer.dart';

class CloudBackupSection extends ConsumerStatefulWidget {
  const CloudBackupSection({super.key});

  @override
  ConsumerState<CloudBackupSection> createState() =>
      _CloudBackupSectionState();
}

class _CloudBackupSectionState
    extends ConsumerState<CloudBackupSection> {

  bool working = false;
  String status = 'No backup prepared';
  String fileName = '';

  Future<void> prepareBackup() async {
    final dbPath = ref.read(activeDatabasePathProvider);

    if (dbPath == null) {
      setState(() => status = 'No project is open');
      return;
    }

    setState(() {
      working = true;
      status = 'Preparing backup...';
    });

    try {
      // Create a local folder for backups awaiting upload.
      final directory = await getApplicationSupportDirectory();
      final folder = Directory(
        path.join(directory.path, 'cloud_backup_queue'),
      );

      await folder.create(recursive: true);

      final name =
          'backup_${DateTime.now().millisecondsSinceEpoch}.sqlite';

      final destination = path.join(folder.path, name);

      // Create and verify a real SQLite backup.
      await SqliteDbBackupWriter().writeDatabaseBackup(
        sourceDbPath: dbPath,
        destinationDbPath: destination,
      );

      if (!mounted) return;

      setState(() {
        fileName = name;
        status = 'Backup prepared - awaiting cloud upload';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => status = 'Backup failed: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloud Backup Preparation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Prepare a verified project backup for future cloud synchronization.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: working ? null : prepareBackup,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Prepare Cloud Backup'),
            ),
            const SizedBox(height: 12),
            Text('Status: $status'),
            if (fileName.isNotEmpty)
              Text('Backup file: $fileName'),
          ],
        ),
      ),
    );
  }
}
