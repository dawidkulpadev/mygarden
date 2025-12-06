import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/device.dart';
import '../models/plant.dart';



enum MoistureRange { day, week, month }

class SoilMoistureHistoryScreen extends StatefulWidget {
  final Device sensor;
  final Plant plant;

  const SoilMoistureHistoryScreen({
    super.key,
    required this.sensor,
    required this.plant,
  });

  @override
  State<SoilMoistureHistoryScreen> createState() =>
      _SoilMoistureHistoryScreenState();
}



class _SoilMoistureHistoryScreenState extends State<SoilMoistureHistoryScreen> {
  MoistureRange _range = MoistureRange.day;

  int _stableStringHash(String s) {
    var hash = 0;
    for (final codeUnit in s.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash;
  }

  List<FlSpot> _generateSpots() {
    int points;
    switch (_range) {
      case MoistureRange.day:
        points = 24;
        break;
      case MoistureRange.week:
        points = 7 * 24;
        break;
      case MoistureRange.month:
        points = 30 * 6;
        break;
    }

    final seed =
        _stableStringHash('${widget.sensor.id}_${_range.toString()}');
    final rand = Random(seed);

    final spots = <FlSpot>[];
    for (var i = 0; i < points; i++) {
      final value = 25 + rand.nextDouble() * 55;
      spots.add(FlSpot(i.toDouble(), double.parse(value.toStringAsFixed(1))));
    }
    return spots;
  }

  String _rangeLabel(MoistureRange r) {
    switch (r) {
      case MoistureRange.day:
        return 'Dzień';
      case MoistureRange.week:
        return 'Tydzień';
      case MoistureRange.month:
        return 'Miesiąc';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spots = _generateSpots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Wilgotność – ${widget.plant.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.opacity_outlined,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.sensor.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final r in MoistureRange.values)
                  ChoiceChip(
                    label: Text(_rangeLabel(r)),
                    selected: _range == r,
                    onSelected: (sel) {
                      if (sel) {
                        setState(() => _range = r);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: cs.outlineVariant,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _range == MoistureRange.day
                                ? 6
                                : _range == MoistureRange.week
                                    ? 24
                                    : 30,
                            getTitlesWidget: (value, meta) {
                              if (value < 0 || value > spots.length - 1) {
                                return const SizedBox.shrink();
                              }
                              String label;
                              switch (_range) {
                                case MoistureRange.day:
                                  label = '${value.toInt()}h';
                                  break;
                                case MoistureRange.week:
                                  final day = (value ~/ 24) + 1;
                                  label = 'D$day';
                                  break;
                                case MoistureRange.month:
                                  final day = (value ~/ 6) + 1;
                                  label = 'D$day';
                                  break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  label,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dane są generowane losowo na potrzeby symulacji.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
