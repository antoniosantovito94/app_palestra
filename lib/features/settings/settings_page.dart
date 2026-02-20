import 'package:flutter/material.dart';
import '../../app/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Impostazioni',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Modalità avanzata'),
                subtitle: const Text(
                  'Abilita peso per serie e funzioni di progressione.',
                ),
                value: appSettings.advancedMode,
                onChanged: appSettings.setAdvancedMode,
              ),
            ],
          ),
        );
      },
    );
  }
}