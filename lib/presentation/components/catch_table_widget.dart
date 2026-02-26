import 'package:flutter/material.dart';
import 'package:ui_prototype/domain/catch_history.dart';
import 'package:ui_prototype/infrastructure/catch_history.dart';

class CatchHistoryTable extends StatelessWidget {
  const CatchHistoryTable({super.key});

  @override
  Widget build(BuildContext context) {
    final catchHistory = HistoryCatch();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black45, width: 1),
                bottom: BorderSide(color: Colors.black45, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black45, width: 2)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: List.generate(8, (i) => [
                        SizedBox(
                          width: getColumnWidth(i),
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
                        if (i < 8) const VerticalDivider(color: Colors.black45, width: 1, thickness: 1),
                      ]).expand((e) => e).toList(),
                    ),
                  ),
                ),

                const Divider(color: Colors.black45, height: 8),

                // Data rows
                ...List.generate(5, (i) => Row(
                  children: List.generate(8, (j) => [
                    SizedBox(
                      width: getColumnWidth(j),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          catchHistory.getValue(i, j).toString(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                          softWrap: false,
                        ),
                      ),
                    ),
                    if (j < 8) const VerticalDivider(color: Colors.black45, width: 1, thickness: 1),
                  ]).expand((e) => e).toList(),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}