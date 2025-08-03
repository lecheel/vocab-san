import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSettingCard(
              title: 'Japanese Repeats',
              subtitle: 'Number of times to repeat the Japanese audio.',
              value: appState.jpRepeats,
              onChanged: (value) => appState.updateJpRepeats(value.toInt()),
            ),
            _buildSettingCard(
              title: 'English Repeats',
              subtitle: 'Number of times to repeat the English audio.',
              value: appState.enRepeats,
              onChanged: (value) => appState.updateEnRepeats(value.toInt()),
            ),
            _buildSettingCard(
              title: 'Delay Between Cards (seconds)',
              subtitle:
                  'The pause duration after a card is finished before moving to the next.',
              value: appState.delaySeconds,
              min: 0,
              max: 10,
              onChanged: (value) => appState.updateDelay(value.toInt()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<double> onChanged,
    double min = 1,
    double max = 5,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value.toDouble(),
                    min: min,
                    max: max,
                    divisions: (max - min).toInt(),
                    label: value.toString(),
                    onChanged: onChanged,
                  ),
                ),
                Text(value.toString(), style: const TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
