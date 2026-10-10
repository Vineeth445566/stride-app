import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../services/ads_service.dart';
import '../services/step_service.dart';

/// Goal, body metrics, sensitivity, themes, privacy, about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<StepService>();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _SectionTitle('Daily goal'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => steps.setGoal(steps.goal - 500),
                ),
                Text('${steps.goal} steps',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => steps.setGoal(steps.goal + 500),
                ),
              ],
            ),
          ),
        ),
        _SectionTitle('Body metrics'),
        Card(
          child: Column(
            children: [
              _StepperRow(
                label: 'Height',
                value: '${steps.heightCm.round()} cm',
                onMinus: () => steps.setHeight(steps.heightCm - 1),
                onPlus: () => steps.setHeight(steps.heightCm + 1),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _StepperRow(
                label: 'Weight',
                value: '${steps.weightKg.round()} kg',
                onMinus: () => steps.setWeight(steps.weightKg - 1),
                onPlus: () => steps.setWeight(steps.weightKg + 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Used only to estimate distance and calories. Stored on this device only.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
        _SectionTitle('Units'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Metric (km)')),
                ButtonSegment(value: false, label: Text('Imperial (mi)')),
              ],
              selected: {steps.metric},
              onSelectionChanged: (s) => steps.setMetric(s.first),
            ),
          ),
        ),
        _SectionTitle('Counting sensitivity'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Low')),
                    ButtonSegment(value: 3, label: Text('Medium')),
                    ButtonSegment(value: 5, label: Text('High')),
                  ],
                  selected: {steps.sensitivity},
                  onSelectionChanged: (s) => steps.setSensitivity(s.first),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Higher sensitivity smooths the live counter; the saved step total is always exact.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _SectionTitle('Themes'),
        Card(
          child: Column(
            children: AppTheme.themes.entries.map((e) {
              final id = e.key;
              final name = e.value['name'] as String;
              final seed = Color(e.value['seed'] as int);
              // When ads are disabled, every theme is free.
              final locked = AdConfig.adsEnabled &&
                  (e.value['locked'] as bool) &&
                  !steps.unlockedThemes.contains(id);
              final selected = steps.themeId == id;
              return ListTile(
                leading: CircleAvatar(backgroundColor: seed),
                title: Text(name),
                trailing: locked
                    ? TextButton.icon(
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Watch ad'),
                        onPressed: () => _unlockWithAd(context, id),
                      )
                    : (selected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null),
                onTap: locked ? null : () => steps.setTheme(id),
              );
            }).toList(),
          ),
        ),
        _SectionTitle('About'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(
                  Uri.parse(Links.privacyPolicy),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Rate Stride on Google Play'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(
                  Uri.parse(Links.playStore),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Stride Step Counter'),
                subtitle: Text(
                    'Version 1.0.0 — free pedometer. Step counting works offline; ads need internet.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _unlockWithAd(BuildContext context, String themeId) async {
    final ads = context.read<AdsService>();
    final steps = context.read<StepService>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Loading reward ad…')),
    );
    final earned = await ads.showRewarded();
    if (!context.mounted) return;
    if (earned) {
      await steps.unlockTheme(themeId);
      await steps.setTheme(themeId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Theme unlocked! Enjoy.')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Ad is not ready yet — please try again shortly.')),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(label,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(icon: const Icon(Icons.remove), onPressed: onMinus),
          SizedBox(
            width: 80,
            child: Text(value, textAlign: TextAlign.center),
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: onPlus),
        ],
      ),
    );
  }
}
