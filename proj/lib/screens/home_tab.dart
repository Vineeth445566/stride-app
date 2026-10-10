import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_utils.dart';
import '../services/step_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/goal_progress_ring.dart';
import '../widgets/step_bar_chart.dart';

/// Today's overview: goal ring, stats, start/pause, and the last 7 days.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatDuration(double minutes) {
    final h = (minutes ~/ 60);
    final m = (minutes % 60).round();
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepService>();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Text(
                    prettyDate(DateTime.now()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (steps.error != null)
                  Card(
                    color: scheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        steps.error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: GoalProgressRing(
                    progress: steps.progress,
                    centerTop: _formatNumber(steps.displayedSteps),
                    centerBottom: 'of ${_formatNumber(steps.goal)} steps',
                  ),
                ),
                if (steps.goalReached)
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.emoji_events, size: 18),
                      label: const Text('Daily goal reached!'),
                      backgroundColor: scheme.primaryContainer,
                    ),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatCard(
                        icon: Icons.route,
                        label: 'Distance',
                        value: steps.distanceDisplay.toStringAsFixed(2),
                        unit: steps.distanceUnit,
                      ),
                      _StatCard(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: steps.calories.toStringAsFixed(0),
                        unit: 'kcal',
                      ),
                      _StatCard(
                        icon: Icons.timer,
                        label: 'Time',
                        value: _formatDuration(steps.durationMin),
                        unit: '',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: FilledButton.icon(
                    onPressed: () =>
                        steps.setTracking(!steps.isTracking),
                    icon: Icon(
                        steps.isTracking ? Icons.pause : Icons.play_arrow),
                    label: Text(steps.isTracking
                        ? 'Pause tracking'
                        : 'Start tracking'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                if (!steps.isTracking)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'Paused — e.g. while driving. Steps are not counted.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('This week',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: FutureBuilder<List<Map<String, Object?>>>(
                      future: steps.lastNDays(7),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const SizedBox(
                              height: 120,
                              child: Center(
                                  child: CircularProgressIndicator()));
                        }
                        final data = snap.data!;
                        return StepBarChart(
                          height: 130,
                          values: data
                              .map((e) => (e['steps'] as int).toDouble())
                              .toList(),
                          labels: data
                              .map((e) => weekdayShort(
                                  dateOfKey(e['date'] as String)))
                              .toList(),
                          highlightIndex: 6,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 6),
              Text(
                unit.isEmpty ? value : '$value $unit',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
