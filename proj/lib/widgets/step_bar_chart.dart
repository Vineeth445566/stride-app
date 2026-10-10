import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Simple bar chart used by the Home week-strip and the History screen.
class StepBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final int? highlightIndex;

  const StepBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b));
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: (maxY * 1.15).clamp(1, double.infinity),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rod.toY.round()}',
                TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final highlighted = highlightIndex != null && i == highlightIndex;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: values.length > 12 ? 10 : 16,
                  borderRadius: BorderRadius.circular(5),
                  color: highlighted ? scheme.primary : scheme.primaryContainer,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
