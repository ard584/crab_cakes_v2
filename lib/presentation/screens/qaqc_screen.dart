import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crab_cakes/infrastructure/providers/project_database_provider.dart';
import 'package:crab_cakes/presentation/screens/check_database_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crab_cakes/domain/entities/row_identifier.dart';

import 'dart:math' as math;

class QaqcScreen extends ConsumerStatefulWidget {
  const QaqcScreen({super.key});

  @override
  ConsumerState<QaqcScreen> createState() => _QaqcScreenState();
}

class _QaqcScreenState extends ConsumerState<QaqcScreen> {
  String selectedSpecies = 'All Species';
  String selectedGraph = 'Length vs. Weight';

  // measurements for X-Y graph
  String selectedXAxis = 'LENGTH_MM';
  String selectedYAxis = 'WEIGHT_G';

  String selectedDate = 'All Dates';
  String selectedLocation = 'All Locations';
  String selectedGear = 'All Gear Types';
  String selectedGroup = 'SPECIES';
  String selectedPivotRow = 'SPECIES';
  String selectedPivotColumn = 'LOCATION';

  // builds filter dropdown
  Widget buildFilter(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option,

          child: Text(
            option.startsWith('All ') ? 'All' : option,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String fieldLabel(String name) {
    if (name.isEmpty) return '';

    String label = name.toLowerCase().replaceAll('_', ' ');

    if (label.endsWith(' mm')) {
      label = '${label.substring(0, label.length - 3)} (mm)';
    } else if (label.endsWith(' g')) {
      label = '${label.substring(0, label.length - 2)} (g)';
    }

    return label[0].toUpperCase() + label.substring(1);
  }

  // creates box to display summary value
  Widget buildSummaryCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // gets current project's database
    final database = ref.watch(projectDatabaseProvider);

    // gets fish records
    final fishRecords = database.getAllRows('SPECIMEN');

    // compares fish measurements within each species
    final ratiosBySpecies = <String, List<double>>{};

    for (final fish in fishRecords) {
      final species = fish.values['SPECIES']?.toString() ?? '';
      final length = fish.values['LENGTH_MM'];
      final weight = fish.values['WEIGHT_G'];

      if (species.isEmpty || length is! num || weight is! num) continue;
      if (length <= 0 || weight <= 0) continue;

      final size = length.toDouble();
      final ratio = weight.toDouble() / (size * size * size);

      ratiosBySpecies.putIfAbsent(species, () => []);
      ratiosBySpecies[species]!.add(ratio);
    }

    // finds typical ratio for each species
    final medianRatios = <String, double>{};

    for (final entry in ratiosBySpecies.entries) {
      final ratios = entry.value;

      if (ratios.length < 5) continue;

      ratios.sort();

      final middle = ratios.length ~/ 2;

      final median = ratios.length.isOdd
          ? ratios[middle]
          : (ratios[middle - 1] + ratios[middle]) / 2;

      medianRatios[entry.key] = median;
    }

    // finds fish with unusual ratios
    final unusualFishIds = <int>{};

    for (final fish in fishRecords) {
      final species = fish.values['SPECIES']?.toString() ?? '';
      final length = fish.values['LENGTH_MM'];
      final weight = fish.values['WEIGHT_G'];
      final median = medianRatios[species];

      if (length is! num || weight is! num || median == null) continue;
      if (length <= 0 || weight <= 0 || median <= 0) continue;

      final size = length.toDouble();
      final ratio = weight.toDouble() / (size * size * size);
      final difference = ratio / median;

      if (difference > 2.5 || difference < 0.4) {
        final id = (fish.identifier as SqliteRowIdentifier).value as int;
        unusualFishIds.add(id);
      }
    }

    // gets different species from fish records
    final speciesList = fishRecords
        .map((fish) => fish.values['SPECIES'].toString())
        .toSet()
        .toList();

    speciesList.sort();

    // finds numeric columns for x-y plots
    final columns = database.getTableSchema('SPECIMEN').columns;

    final numericFields = columns
        .where((column) {
          final type = column.type.toUpperCase();

          return !column.primaryKey &&
              !column.name.startsWith('__') &&
              (type.contains('INT') ||
                  type.contains('REAL') ||
                  type.contains('DECIMAL') ||
                  type.contains('NUMERIC') ||
                  type.contains('FLOAT') ||
                  type.contains('DOUBLE'));
        })
        .map((column) => column.name)
        .toList();

    final customPlot = selectedGraph == 'Custom X-Y Plot';

    final xField = customPlot
        ? (numericFields.contains(selectedXAxis)
              ? selectedXAxis
              : (numericFields.isNotEmpty ? numericFields.first : ''))
        : 'LENGTH_MM';

    final yField = customPlot
        ? (numericFields.contains(selectedYAxis)
              ? selectedYAxis
              : (numericFields.length > 1 ? numericFields[1] : xField))
        : 'WEIGHT_G';

    // gets filter options from database
    List<String> getOptions(String field) {
      final options = fishRecords
          .map((fish) => fish.values[field]?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

      options.sort();
      return options;
    }

    final dates = getOptions('SURVEY_DATE');
    final locations = getOptions('LOCATION');
    final gearTypes = getOptions('GEAR_TYPE');

    final dateFilter = dates.contains(selectedDate)
        ? selectedDate
        : 'All Dates';

    final locationFilter = locations.contains(selectedLocation)
        ? selectedLocation
        : 'All Locations';

    final gearFilter = gearTypes.contains(selectedGear)
        ? selectedGear
        : 'All Gear Types';

    // filters records by survey information
    final surveyFish = fishRecords.where((fish) {
      if (dateFilter != 'All Dates' &&
          fish.values['SURVEY_DATE']?.toString() != dateFilter) {
        return false;
      }

      if (locationFilter != 'All Locations' &&
          fish.values['LOCATION']?.toString() != locationFilter) {
        return false;
      }

      if (gearFilter != 'All Gear Types' &&
          fish.values['GEAR_TYPE']?.toString() != gearFilter) {
        return false;
      }

      return true;
    }).toList();

    // counts fish after filtering
    final speciesCounts = <String, int>{};

    for (final fish in surveyFish) {
      final species = fish.values['SPECIES'].toString();

      if (speciesCounts.containsKey(species)) {
        speciesCounts[species] = speciesCounts[species]! + 1;
      } else {
        speciesCounts[species] = 1;
      }
    }

    // creates bar for each species
    final barGroups = <BarChartGroupData>[];

    for (int i = 0; i < speciesList.length; i++) {
      final species = speciesList[i];
      final count = speciesCounts[species] ?? 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 25,
            ),
          ],
        ),
      );
    }

    // applies species filter
    final filteredFish = selectedSpecies == 'All Species'
        ? surveyFish
        : surveyFish.where((fish) {
            return fish.values['SPECIES'] == selectedSpecies;
          }).toList();

    // gets fields for grouping
    final groupFields = ['SPECIES', 'SURVEY_DATE', 'LOCATION', 'GEAR_TYPE']
        .where((field) {
          return columns.any((column) => column.name == field);
        })
        .toList();

    final groupField = groupFields.contains(selectedGroup)
        ? selectedGroup
        : (groupFields.isNotEmpty ? groupFields.first : '');

    // counts fish in each group
    final groupCounts = <String, int>{};

    for (final fish in filteredFish) {
      if (groupField.isEmpty) continue;

      final group = fish.values[groupField]?.toString() ?? '';

      if (group.isNotEmpty) {
        groupCounts[group] = (groupCounts[group] ?? 0) + 1;
      }
    }

    final groupNames = groupCounts.keys.toList()..sort();

    // chooses pivot table fields
    final pivotRowField = groupFields.contains(selectedPivotRow)
        ? selectedPivotRow
        : (groupFields.isNotEmpty ? groupFields.first : '');

    final pivotColumnField = groupFields.contains(selectedPivotColumn)
        ? selectedPivotColumn
        : (groupFields.isNotEmpty ? groupFields.last : '');

    // counts fish for each row and column
    final pivotCounts = <String, Map<String, int>>{};
    final pivotColumnTotals = <String, int>{};
    int pivotTotal = 0;

    for (final fish in filteredFish) {
      if (pivotRowField.isEmpty || pivotColumnField.isEmpty) continue;

      final rowName = fish.values[pivotRowField]?.toString() ?? '';
      final columnName = fish.values[pivotColumnField]?.toString() ?? '';

      if (rowName.isEmpty || columnName.isEmpty) continue;

      pivotCounts.putIfAbsent(rowName, () => <String, int>{});

      final rowCounts = pivotCounts[rowName]!;

      rowCounts[columnName] = (rowCounts[columnName] ?? 0) + 1;
      pivotColumnTotals[columnName] = (pivotColumnTotals[columnName] ?? 0) + 1;

      pivotTotal++;
    }

    final pivotRows = pivotCounts.keys.toList()..sort();
    final pivotColumns = pivotColumnTotals.keys.toList()..sort();

    // collects measurements for each group
    final pivotLengths = <String, List<double>>{};
    final pivotWeights = <String, List<double>>{};

    for (final fish in filteredFish) {
      if (pivotRowField.isEmpty || pivotColumnField.isEmpty) continue;

      final row = fish.values[pivotRowField]?.toString() ?? '';
      final column = fish.values[pivotColumnField]?.toString() ?? '';

      if (row.isEmpty || column.isEmpty) continue;

      final length = fish.values['LENGTH_MM'];
      final weight = fish.values['WEIGHT_G'];

      if (length is num) {
        pivotLengths.putIfAbsent(row, () => []);
        pivotLengths[row]!.add(length.toDouble());
      }

      if (weight is num) {
        pivotWeights.putIfAbsent(row, () => []);
        pivotWeights[row]!.add(weight.toDouble());
      }
    }

    // calculates average measurement
    String getAverage(List<double>? values) {
      if (values == null || values.isEmpty) return '-';

      double total = 0;

      for (final value in values) {
        total += value;
      }

      return (total / values.length).toStringAsFixed(1);
    }

    final allLengths = pivotLengths.values.expand((values) => values).toList();
    final allWeights = pivotWeights.values.expand((values) => values).toList();

    // makes points from selected measurements
    final fishPoints = <ScatterSpot>[];

    // keeps track of database record for each point
    final fishRowIds = <int>[];

    // keeps species for each point on the graph
    final fishSpecies = <String>[];

    for (final fish in filteredFish) {
      final xValue = fish.values[xField];
      final yValue = fish.values[yField];

      if (xValue is num && yValue is num) {
        final fishId = (fish.identifier as SqliteRowIdentifier).value as int;

        // highlights unusual fish on length-weight graph
        final isUnusual =
            selectedGraph == 'Length vs. Weight' &&
            unusualFishIds.contains(fishId);

        fishPoints.add(
          ScatterSpot(
            xValue.toDouble(),
            yValue.toDouble(),
            dotPainter: FlDotCirclePainter(
              radius: 5,
              color: isUnusual ? Colors.red : Colors.blue,
            ),
          ),
        );

        fishSpecies.add(fish.values['SPECIES'].toString());
        fishRowIds.add(fishId);
      }
    }

    // calculates average length and weight
    double totalLength = 0;
    double totalWeight = 0;

    for (final point in fishPoints) {
      totalLength += point.x;
      totalWeight += point.y;
    }

    final averageLength = fishPoints.isEmpty
        ? 0.0
        : totalLength / fishPoints.length;

    final averageWeight = fishPoints.isEmpty
        ? 0.0
        : totalWeight / fishPoints.length;

    // finds smallest and largest measurements
    final minLength = fishPoints.isEmpty
        ? 0.0
        : fishPoints.map((p) => p.x).reduce(math.min);

    final maxLength = fishPoints.isEmpty
        ? 0.0
        : fishPoints.map((p) => p.x).reduce(math.max);

    final minWeight = fishPoints.isEmpty
        ? 0.0
        : fishPoints.map((p) => p.y).reduce(math.min);

    final maxWeight = fishPoints.isEmpty
        ? 0.0
        : fishPoints.map((p) => p.y).reduce(math.max);

    // chooses spacing between axis
    final xStep = maxLength - minLength > 150 ? 50.0 : 25.0;
    final yStep = maxWeight - minWeight > 400
        ? 100.0
        : maxWeight - minWeight > 150
        ? 50.0
        : 25.0;

    // adds space around the measurements
    final chartMinX = math.max(0.0, ((minLength - 15) / xStep).floor() * xStep);
    final chartMaxX = ((maxLength + 15) / xStep).ceil() * xStep;

    final chartMinY = math.max(0.0, ((minWeight - 15) / yStep).floor() * yStep);
    final chartMaxY = ((maxWeight + 15) / yStep).ceil() * yStep;

    return Scaffold(
      appBar: AppBar(title: const Text('QA/QC Graphs')),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // chooses which graph to display
            DropdownButton<String>(
              value: selectedGraph,
              items: const [
                DropdownMenuItem(
                  value: 'Length vs. Weight',
                  child: Text('Length vs. Weight'),
                ),
                DropdownMenuItem(
                  value: 'Species Count',
                  child: Text('Species Count'),
                ),
                DropdownMenuItem(
                  value: 'Custom X-Y Plot',
                  child: Text('Custom X-Y Plot'),
                ),

                DropdownMenuItem(
                  value: 'Grouped Summary',
                  child: Text('Grouped Summary'),
                ),

                DropdownMenuItem(
                  value: 'Pivot Table',
                  child: Text('Pivot Table'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedGraph = value;
                  });
                }
              },
            ),

            const SizedBox(height: 12),

            // displays title of selected graph
            Text(
              selectedGraph == 'Length vs. Weight'
                  ? 'Fish Length vs. Weight'
                  : selectedGraph == 'Species Count'
                  ? 'Fish Counts by Species'
                  : selectedGraph == 'Custom X-Y Plot'
                  ? 'Custom X-Y Plot'
                  : selectedGraph == 'Grouped Summary'
                  ? 'Grouped Survey Summary'
                  : 'Survey Pivot Table',

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // filters for graph data
            Row(
              children: [
                if (selectedGraph != 'Species Count') ...[
                  Expanded(
                    child: buildFilter(
                      'Species',
                      selectedSpecies,
                      ['All Species', ...speciesList],
                      (value) {
                        if (value != null) {
                          setState(() {
                            selectedSpecies = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (dates.isNotEmpty) ...[
                  Expanded(
                    child: buildFilter(
                      'Date',
                      dateFilter,
                      ['All Dates', ...dates],
                      (value) {
                        if (value != null) {
                          setState(() {
                            selectedDate = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (locations.isNotEmpty) ...[
                  Expanded(
                    child: buildFilter(
                      'Location',
                      locationFilter,
                      ['All Locations', ...locations],
                      (value) {
                        if (value != null) {
                          setState(() {
                            selectedLocation = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (gearTypes.isNotEmpty) ...[
                  Expanded(
                    child: buildFilter(
                      'Gear',
                      gearFilter,
                      ['All Gear Types', ...gearTypes],
                      (value) {
                        if (value != null) {
                          setState(() {
                            selectedGear = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedSpecies = 'All Species';
                      selectedDate = 'All Dates';
                      selectedLocation = 'All Locations';
                      selectedGear = 'All Gear Types';
                    });
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),

            // chooses how to group records
            if (selectedGraph == 'Grouped Summary' && groupFields.isNotEmpty)
              DropdownButton<String>(
                value: groupField,
                items: groupFields.map((field) {
                  return DropdownMenuItem(
                    value: field,
                    child: Text(fieldLabel(field)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedGroup = value;
                    });
                  }
                },
              ),

            // pivot table fields
            if (selectedGraph == 'Pivot Table' && groupFields.isNotEmpty)
              Row(
                children: [
                  const Text('Rows: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: pivotRowField,
                      isExpanded: true,
                      items: groupFields.map((field) {
                        return DropdownMenuItem(
                          value: field,
                          child: Text(fieldLabel(field)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPivotRow = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Text('Columns: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: pivotColumnField,
                      isExpanded: true,
                      items: groupFields.map((field) {
                        return DropdownMenuItem(
                          value: field,
                          child: Text(fieldLabel(field)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedPivotColumn = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

            // selects measurements for custom graph
            if (customPlot && numericFields.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('x-$xField'),
                      initialValue: xField,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'X Axis'),
                      items: numericFields.map((field) {
                        return DropdownMenuItem(
                          value: field,
                          child: Text(fieldLabel(field)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedXAxis = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('y-$yField'),
                      initialValue: yField,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Y Axis'),
                      items: numericFields.map((field) {
                        return DropdownMenuItem(
                          value: field,
                          child: Text(fieldLabel(field)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedYAxis = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

            if (customPlot && numericFields.isEmpty)
              const Text('No numeric measurements available.'),

            const SizedBox(height: 16),

            Expanded(
              child: selectedGraph == 'Pivot Table'
                  ? pivotRows.isEmpty
                        ? const Center(
                            child: Text('No fish match these filters.'),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columnSpacing: 12,
                                horizontalMargin: 10,
                                headingRowHeight: 48,
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 52,
                                columns: [
                                  DataColumn(
                                    label: Text(fieldLabel(pivotRowField)),
                                  ),
                                  for (final columnName in pivotColumns)
                                    DataColumn(label: Text(columnName)),
                                  const DataColumn(label: Text('Total')),

                                  const DataColumn(
                                    label: Text('Avg. Length (mm)'),
                                  ),
                                  const DataColumn(
                                    label: Text('Avg. Weight (g)'),
                                  ),
                                ],
                                rows: [
                                  for (final rowName in pivotRows)
                                    DataRow(
                                      cells: [
                                        DataCell(Text(rowName)),
                                        for (final columnName in pivotColumns)
                                          DataCell(
                                            Text(
                                              '${pivotCounts[rowName]?[columnName] ?? 0}',
                                            ),
                                          ),
                                        DataCell(
                                          Text(
                                            '${pivotCounts[rowName]!.values.fold<int>(0, (total, count) => total + count)}',
                                          ),
                                        ),

                                        DataCell(
                                          Text(
                                            getAverage(pivotLengths[rowName]),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            getAverage(pivotWeights[rowName]),
                                          ),
                                        ),
                                      ],
                                    ),

                                  // totals for each column
                                  DataRow(
                                    cells: [
                                      const DataCell(Text('Total')),
                                      for (final columnName in pivotColumns)
                                        DataCell(
                                          Text(
                                            '${pivotColumnTotals[columnName] ?? 0}',
                                          ),
                                        ),
                                      DataCell(Text('$pivotTotal')),

                                      DataCell(Text(getAverage(allLengths))),
                                      DataCell(Text(getAverage(allWeights))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                  : selectedGraph == 'Grouped Summary'
                  ? groupCounts.isEmpty
                        ? const Center(
                            child: Text('No fish match these filters.'),
                          )
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Group')),
                                DataColumn(
                                  label: Text('Fish Count'),
                                  numeric: true,
                                ),
                              ],
                              rows: groupNames.map((name) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(name)),
                                    DataCell(Text('${groupCounts[name]}')),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                  : selectedGraph != 'Species Count'
                  ? fishPoints.isEmpty
                        ? const Center(
                            child: Text('No fish match these filters.'),
                          )
                        : ScatterChart(
                            ScatterChartData(
                              scatterSpots: fishPoints,

                              // shows fish information when point is selected
                              scatterTouchData: ScatterTouchData(
                                touchSpotThreshold: 12,

                                // find the database record when a fish is clicked
                                touchCallback: (event, response) async {
                                  if (event is FlTapUpEvent &&
                                      response?.touchedSpot != null) {
                                    final index =
                                        response!.touchedSpot!.spotIndex;

                                    if (index >= 0 &&
                                        index < fishRowIds.length) {
                                      final fishId = fishRowIds[index];

                                      // opens selected fish in Check Database
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CheckDatabaseScreen(
                                                selectedFishId: fishId,
                                              ),
                                        ),
                                      );

                                      // refreshes graph when returning from database
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    }
                                  }
                                },
                                touchTooltipData: ScatterTouchTooltipData(
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItems: (point) {
                                    final index = fishPoints.indexOf(point);

                                    final species =
                                        index >= 0 && index < fishSpecies.length
                                        ? fishSpecies[index]
                                        : 'Unknown Species';

                                    // checks if fish needs review
                                    final needsReview =
                                        index >= 0 &&
                                        index < fishRowIds.length &&
                                        unusualFishIds.contains(
                                          fishRowIds[index],
                                        ) &&
                                        selectedGraph == 'Length vs. Weight';

                                    final warning = needsReview
                                        ? '\nPossible outlier - review'
                                        : '';

                                    return ScatterTooltipItem(
                                      '$species\n'
                                      '${fieldLabel(xField)}: ${point.x.toStringAsFixed(1)}\n'
                                      '${fieldLabel(yField)}: ${point.y.toStringAsFixed(1)}$warning',
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              minX: chartMinX,
                              maxX: chartMaxX,
                              minY: chartMinY,
                              maxY: chartMaxY,

                              // sets up graph axes
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  axisNameWidget: Text(fieldLabel(yField)),
                                  axisNameSize: 30,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 45,
                                    interval: yStep,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    interval: xStep,
                                  ),
                                ),
                              ),

                              // horizontal gridlines
                              gridData: const FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 100,
                              ),
                            ),
                          )
                  : barGroups.isEmpty
                  ? const Center(child: Text('No fish match these filters.'))
                  : BarChart(
                      BarChartData(
                        // uses species counts from database
                        barGroups: barGroups,
                        maxY:
                            (speciesCounts.values.fold<int>(
                                      0,
                                      (highest, count) =>
                                          count > highest ? count : highest,
                                    ) +
                                    2)
                                .toDouble(),

                        alignment: BarChartAlignment.spaceAround,

                        // sets up bar graph axes
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              interval: 1,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 55,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();

                                if (index < 0 || index >= speciesList.length) {
                                  return const SizedBox.shrink();
                                }

                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    speciesList[index].replaceAll(' ', '\n'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            if (selectedGraph == 'Length vs. Weight' ||
                selectedGraph == 'Custom X-Y Plot')
              Text(fieldLabel(xField)),

            const SizedBox(height: 8),

            // explains red dots
            if (selectedGraph == 'Length vs. Weight')
              const Text(
                'Red dots indicate potential unusual measurement',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),

            const SizedBox(height: 8),

            // shows summaries for length and weight graph
            if (selectedGraph == 'Length vs. Weight')
              Row(
                children: [
                  buildSummaryCard('Fish Count', '${fishPoints.length}'),
                  buildSummaryCard(
                    'Avg. Length',
                    '${averageLength.toStringAsFixed(1)} mm',
                  ),
                  buildSummaryCard(
                    'Avg. Weight',
                    '${averageWeight.toStringAsFixed(1)} g',
                  ),
                ],
              )
            else if (selectedGraph == 'Species Count')
              Text('Total fish: ${surveyFish.length}')
            else if (selectedGraph == 'Grouped Summary' ||
                selectedGraph == 'Pivot Table')
              Text('Total fish: ${filteredFish.length}')
            else
              Text('Showing ${fishPoints.length} fish'),
          ],
        ),
      ),
    );
  }
}
