import 'package:flutter/material.dart';
import 'package:ui_prototype/application/table_repository.dart';
import 'package:ui_prototype/domain/catch_history.dart';
import 'package:ui_prototype/infrastructure/catch_history.dart';
import 'package:ui_prototype/presentation/view_models/project_input.dart';
import 'package:ui_prototype/domain/entities/row_identifier.dart';

class CatchHistoryTable extends StatelessWidget {
  final ActiveProjectRepository<RowIdentifier> db;
  final TableInput table;

  static const int kHistoryRowCount = 5;

  const CatchHistoryTable({super.key, required this.db, required this.table});

  @override
  Widget build(BuildContext context) {
    final viewModel = CatchHistoryViewModel(db: db, table: table);
    final catchHistory = HistoryCatch(viewModel: viewModel);
    final columnCount = viewModel.getColumnCount();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: 150,
      child: Container(
        padding: const EdgeInsets.all(0),
        alignment: Alignment.centerRight,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Colors.black45, width: 1),
              right: BorderSide(color: Colors.black45, width: 1),
              bottom: BorderSide(color: Colors.black45, width: 1),
              top: BorderSide(color: Colors.black45, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black45, width: 2)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(columnCount, (i) => [
                        SizedBox(
                          width: viewModel.getColumnWidth(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Text(
                              catchHistory.getColumnName(i),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ),
                        if (i < columnCount - 1) const VerticalDivider(color: Colors.black45, width: 1, thickness: 1),
                      ]).expand((e) => e).toList(),
                    ),
                  ),
                ),

                const Divider(color: Colors.black45, height: 8),

                // Data rows — most recent at bottom, oldest at top
                ...List.generate(kHistoryRowCount, (i) {
                  final reversedI = 4 - i;
                  return Row(
                    children: List.generate(columnCount, (j) => [
                      SizedBox(
                        width: viewModel.getColumnWidth(j),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            catchHistory.getValue(reversedI, j).toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                            softWrap: false,
                          ),
                        ),
                      ),
                      if (j < columnCount - 1) const VerticalDivider(color: Colors.black45, width: 1, thickness: 1),
                    ]).expand((e) => e).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}