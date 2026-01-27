import 'package:flutter/material.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsetsGeometry.all(40),
            child: Column(
              children: <Widget>[
                SimpleTable(
                  headers: ['H1', 'H2', 'H3'],
                  data: [
                    ['Data1', 'Data2', 'Data3'],
                    ['Data4', 'Data5', 'Data6'],
                    ['Data7', 'Data8', 'Data9'],
                  ],
                ),
                FloatingActionButton.extended(
                  onPressed: null,
                  label: Text('Export to File'),
                  icon: Icon(Icons.file_download),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class SimpleTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> data;

  const SimpleTable({super.key, required this.headers, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        // Set the border style for the entire table
        border: TableBorder.all(
          color: Colors.grey.shade300,
          width: 1.0,
          borderRadius: BorderRadius.circular(8.0),
        ),
        // ColumnWidths can be used to control how columns take space
        columnWidths: const {
          // You can set the first column (index 0) to be a fixed width
          0: IntrinsicColumnWidth(),
          // Or let others flex to take available space
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
        },
        children: [
          // 1. Header Row
          TableRow(
            decoration: BoxDecoration(
              color: Colors.grey.shade200, // Light background for the header
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8.0),
              ),
            ),
            children: headers
                .map((header) => _buildTableCell(header, isHeader: true))
                .toList(),
          ),

          // 2. Data Rows
          ...data
              .map(
                (row) => TableRow(
                  children: row
                      .map((cellData) => _buildTableCell(cellData))
                      .toList(),
                ),
              )
        ],
      ),
    );
  }

  // Helper method to build a standardized table cell
  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 16 : 14,
          color: isHeader ? Colors.black : Colors.grey.shade700,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }
}
