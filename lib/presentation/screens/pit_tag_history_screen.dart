import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// Prototype for importing and searching previous PIT tag capture records.
class PitTagHistoryScreen extends StatefulWidget {
  const PitTagHistoryScreen({super.key});

  @override
  State<PitTagHistoryScreen> createState() => _PitTagHistoryScreenState();
}

class _PitTagHistoryScreenState extends State<PitTagHistoryScreen> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();

  List<Map<String, String>> _history = [];
  String? _fileName;
  String? _error;
  bool _importing = false;

  @override
  void dispose() {
    _tagController.dispose();
    _speciesController.dispose();
    super.dispose();
  }

  Future<void> _importHistory() async {
    setState(() {
      _importing = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tsv', 'txt'],
        withData: true,
      );

      if (result == null) return;

      final file = result.files.single;
      final text = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();

      final lines = const LineSplitter()
          .convert(text)
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.length < 2) {
        throw const FormatException('History file needs a header and at least one record.');
      }

      final headers = lines.first
          .replaceFirst('\uFEFF', '')
          .split('\t')
          .map((name) => name.trim().toUpperCase())
          .toList();

      const required = [
        'PIT_TAG',
        'SPECIES',
        'LENGTH_MM',
        'WEIGHT_G',
        'RIVER_MILE',
        'CAPTURE_DATE',
      ];

      for (final name in required) {
        if (!headers.contains(name)) {
          throw FormatException('Missing column: $name');
        }
      }

      final records = <Map<String, String>>[];
      for (final line in lines.skip(1)) {
        final values = line.split('\t');
        if (values.length != headers.length) {
          throw const FormatException('A row has the wrong number of columns.');
        }

        final record = <String, String>{};
        for (int i = 0; i < headers.length; i++) {
          record[headers[i]] = values[i].trim();
        }
        records.add(record);
      }

      if (!mounted) return;
      setState(() {
        _history = records;
        _fileName = file.name;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not import history: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
        });
      }
    }
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Biomark tag IDs may contain a dot between groups of hexadecimal digits.
    // Ignore the dot when comparing the 13 hexadecimal characters.
    final tag = _tagController.text.trim().toUpperCase();
    final normalizedTag = tag.replaceAll('.', '');
    final validTag = RegExp(r'^[0-9A-F]{13}$').hasMatch(normalizedTag);

    final matches = validTag
        ? _history.where((record) {
            final savedTag = (record['PIT_TAG'] ?? '')
                .trim()
                .toUpperCase()
                .replaceAll('.', '');
            return savedTag == normalizedTag;
          }).toList()
        : <Map<String, String>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('PIT Tag History Lookup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prototype: Import past capture records and look up a PIT tag.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _importing ? null : _importHistory,
              icon: const Icon(Icons.file_upload_outlined),
              label: Text(_importing ? 'Importing...' : 'Import History TSV'),
            ),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Loaded: $_fileName (${_history.length} records)'),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _tagController,
              maxLength: 14,
              decoration: const InputDecoration(
                labelText: 'PIT Tag Number',
                hintText: 'Example: 3DD.003BFB88EC',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Current Species (optional comparison)',
                hintText: 'For example, Rainbow Trout',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            if (_history.isEmpty)
              const Text('Import a history file to start searching.')
            else if (!validTag)
              const Text('Enter 13 hexadecimal characters (the dot is optional).')
            else if (matches.isEmpty)
              const Text('No previous capture records found for this tag.')
            else ...[
              Text(
                '${matches.length} previous capture record(s) found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              for (final record in matches) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detail('PIT Tag', record['PIT_TAG'] ?? ''),
                        _detail('Previous Species', record['SPECIES'] ?? ''),
                        _detail('Previous Length', '${record['LENGTH_MM'] ?? ''} mm'),
                        _detail('Previous Weight', '${record['WEIGHT_G'] ?? ''} g'),
                        _detail('River Mile', record['RIVER_MILE'] ?? ''),
                        _detail('Capture Date', record['CAPTURE_DATE'] ?? ''),
                        if (_speciesController.text.trim().isNotEmpty &&
                            _speciesController.text.trim().toLowerCase() !=
                                (record['SPECIES'] ?? '').toLowerCase())
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Warning: Current species differs from previous capture.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
