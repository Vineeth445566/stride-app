import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_utils.dart';
import '../services/step_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/step_bar_chart.dart';

enum _Range { day, week, month, year }

/// Step history with Day / Week / Month / Year charts.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<_Range>(
            segments: const [
              ButtonSegment(value: _Range.day, label: Text('Day')),
              ButtonSegment(value: _Range.week, label: Text('Week')),
              ButtonSegment(value: _Range.month, label: Text('Month')),
              ButtonSegment(value: _Range.year, label: Text('Year')),
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  child: _ChartBody(range: _range, key: ValueKey(_range)),
                ),
              ),
              _SummaryCard(range: _range, key: ValueKey('sum-$_range')),
            ],
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}

class _ChartBody extends StatelessWidget {
  final _Range range;
  const _ChartBody({super.key, required this.range});

  @override
  Widget build(BuildContext context) {
    final steps = context.read<StepService>();
    late final Future<({List<double> values, List<String> labels})> future;
    switch (range) {
      case _Range.day:
        future = steps.todayHours().then((hours) => (
              values: hours.map((e) => e.toDouble()).toList(),
              labels: List.generate(24, (i) => i % 3 == 0 ? '${i}h' : ''),
            ));
      case _Range.week:
        future = steps.lastNDays(7).then((rows) => (
              values: rows.map((e) => (e['steps'] as int).toDouble()).toList(),
              labels: rows
                  .map((e) => weekdayShort(dateOfKey(e['date'] as String)))
                  .toList(),
            ));
      case _Range.month:
        future = steps.lastNDays(30).then((rows) => (
              values: rows.map((e) => (e['steps'] as int).toDouble()).toList(),
              labels: List.generate(30, (i) {
                if (i % 5 != 0) return '';
                final d = dateOfKey(rows[i]['date'] as String);
                return '${d.day}';
              }),
            ));
      case _Range.year:
        future = steps.last12Months().then((rows) => (
              values: rows.map((e) => (e['steps'] as int).toDouble()).toList(),
              labels: rows.map((e) => e['label'] as String).toList(),
            ));
    }
    return FutureBuilder<({List<double> values, List<String> labels})>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }
        final d = snap.data!;
        return StepBarChart(
          height: 220,
          values: d.values,
          labels: d.labels,
          highlightIndex: range == _Range.week ? 6 : null,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _Range range;
  const _SummaryCard({super.key, required this.range});

  @override
  Widget build(BuildContext context) {
    final steps = context.read<StepService>();
    final Future<int> totalFuture;
    switch (range) {
      case _Range.day:
        totalFuture = Future.value(steps.todaySteps);
      case _Range.week:
        totalFuture = steps
            .lastNDays(7)
            .then((r) => r.fold<int>(0, (a, e) => a + (e['steps'] as int)));
      case _Range.month:
        totalFuture = steps
            .lastNDays(30)
            .then((r) => r.fold<int>(0, (a, e) => a + (e['steps'] as int)));
      case _Range.year:
        totalFuture = steps
            .last12Months()
            .then((r) => r.fold<int>(0, (a, e) => a + (e['steps'] as int)));
    }
    const titles = {
      _Range.day: 'Today',
      _Range.week: 'Last 7 days',
      _Range.month: 'Last 30 days',
      _Range.year: 'Last 12 months',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<int>(
          future: totalFuture,
          builder: (context, snap) {
            final total = snap.data ?? 0;
            final dist = total * steps.strideM / 1000;
            final distStr = steps.metric
                ? '${dist.toStringAsFixed(1)} km'
                : '${(dist * 0.621371).toStringAsFixed(1)} mi';
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Summary(title: titles[range]!, value: '$total', unit: 'steps'),
                _Summary(title: 'Distance', value: distStr, unit: ''),
                _Summary(
                    title: 'Avg / day',
                    value: range == _Range.day
                        ? '$total'
                        : '${(total / (range == _Range.week ? 7 : range == _Range.month ? 30 : 365)).round()}',
                    unit: 'steps'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  const _Summary({required this.title, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty)
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
