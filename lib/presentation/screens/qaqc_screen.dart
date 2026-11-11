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

    // gets different species from fish records
    final speciesList = fishRecords
        .map((fish) => fish.values['SPECIES'].toString())
        .toSet()
        .toList();

    speciesList.sort();

    // counts how many fish for each species
    final speciesCounts = <String, int>{};

    for (final fish in fishRecords) {
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

    // only use records for selected species
    final filteredFish = selectedSpecies == 'All Species'
        ? fishRecords
        : fishRecords.where((fish) {
            return fish.values['SPECIES'] == selectedSpecies;
          }).toList();

    // makes point for each fish using length and weight
    final fishPoints = <ScatterSpot>[];

    // keeps track of database record for each point
    final fishRowIds = <int>[];

    // keeps species for each point on the graph
    final fishSpecies = <String>[];

    for (final fish in filteredFish) {
      final length = fish.values['LENGTH_MM'];
      final weight = fish.values['WEIGHT_G'];

      if (length is num && weight is num) {
        fishPoints.add(
          ScatterSpot(
            length.toDouble(),
            weight.toDouble(),
            dotPainter: FlDotCirclePainter(radius: 5, color: Colors.blue),
          ),
        );
        fishSpecies.add(fish.values['SPECIES'].toString());
        fishRowIds.add((fish.identifier as SqliteRowIdentifier).value as int);
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
      appBar: AppBar(
        title: const Text('QA/QC Graphs'),
        actions: [
          // Shows features planned for later development
          PopupMenuButton<String>(
            tooltip: 'Future QA/QC Features',
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Custom X-Y Plots'),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Additional Filters'),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Group By'),
              ),
              PopupMenuItem<String>(
                enabled: false,
                child: Text('Pivot Tables'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Future Features'),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),

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
                  : 'Fish Counts by Species',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // only shows species filter for scatter plot
            if (selectedGraph == 'Length vs. Weight')
              DropdownButton<String>(
                value: selectedSpecies,
                items: [
                  const DropdownMenuItem(
                    value: 'All Species',
                    child: Text('All Species'),
                  ),
                  for (final species in speciesList)
                    DropdownMenuItem(value: species, child: Text(species)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSpecies = value;
                    });
                  }
                },
              ),

            const SizedBox(height: 16),

            Expanded(
              child: selectedGraph == 'Length vs. Weight'
                  ? ScatterChart(
                      ScatterChartData(
                        scatterSpots: fishPoints,

                        // shows fish information when point is selected
                        scatterTouchData: ScatterTouchData(
                          touchSpotThreshold: 12,

                          // Find the database record when a fish is clicked
                          touchCallback: (event, response) async {
                            if (event is FlTapUpEvent &&
                                response?.touchedSpot != null) {
                              final index = response!.touchedSpot!.spotIndex;

                              if (index >= 0 && index < fishRowIds.length) {
                                final fishId = fishRowIds[index];

                                // opens selected fish in Check Database
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckDatabaseScreen(
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

                              final species = index >= 0
                                  ? fishSpecies[index]
                                  : 'Unknown Species';

                              return ScatterTooltipItem(
                                '$species\n'
                                'Length: ${point.x.toStringAsFixed(0)} mm\n'
                                'Weight: ${point.y.toStringAsFixed(0)} g',
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
                            axisNameWidget: Text('Weight (g)'),
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

            if (selectedGraph == 'Length vs. Weight') const Text('Length (mm)'),

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
            else
              Text('Total fish: ${fishRecords.length}'),
          ],
        ),
      ),
    );
  }
}
