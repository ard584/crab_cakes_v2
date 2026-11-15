import 'package:flutter/material.dart';

// Shows example capture history when the test PIT tag is entered.
class PitHistoryInline extends StatelessWidget {
  final TextEditingController tagController;

  const PitHistoryInline({
    super.key,
    required this.tagController,
  });

  static const testTag = '3DD003BFB88EC';

  // Fictional previous captures for prototype testing.
  static const records = [
    ['2025-06-12', 'Humpback Chub', '238', '165', '85.1'],
    ['2024-05-21', 'Humpback Chub', '225', '142', '85.4'],
    ['2023-09-03', 'Humpback Chub', '208', '110', '84.9'],
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: tagController,
      builder: (context, value, child) {
        final tag = value.text.toUpperCase()
            .replaceAll(RegExp(r'[^0-9A-F]'), '');

        // Only show history after entering the test tag.
        if (tag != testTag) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F7FB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF8BA9C0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Previous PIT Tag Captures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text('PIT Tag: 3DD.003BFB88EC'),
              const Text('3 previous capture records found'),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Species')),
                    DataColumn(label: Text('Length (mm)')),
                    DataColumn(label: Text('Weight (g)')),
                    DataColumn(label: Text('River Mile')),
                  ],
                  rows: records.map((record) {
                    return DataRow(
                      cells: record.map((item) {
                        return DataCell(Text(item));
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),


            ],
          ),
        );
      },
    );
  }
}
