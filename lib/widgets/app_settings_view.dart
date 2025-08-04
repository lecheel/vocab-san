// lib/widgets/app_settings_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';

class AppSettingsView extends StatefulWidget {
  const AppSettingsView({super.key});

  @override
  State<AppSettingsView> createState() => _AppSettingsViewState();
}

class _AppSettingsViewState extends State<AppSettingsView> {
  late final TextEditingController _urlController;
  final _formKey = GlobalKey<FormState>();

  // This will hold the selected radio button value. It's either a URL
  // from the predefined list or the special string 'custom'.
  String _selectedUrlOption = '';

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUrl = appState.manifestUrl;
    _urlController = TextEditingController(text: currentUrl);

    // Check if the current URL is one of the predefined ones.
    final predefinedUrls = AppState.PREDEFINED_MANIFESTS.map((e) => e['url']);
    if (predefinedUrls.contains(currentUrl)) {
      _selectedUrlOption = currentUrl;
    } else {
      // If it's not a predefined URL, it must be a custom one.
      _selectedUrlOption = 'custom';
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final appState = Provider.of<AppState>(context, listen: false);
      final newUrl = _urlController.text.trim();

      // Only update and refetch if the URL has actually changed.
      if (newUrl != appState.manifestUrl) {
        appState.updateManifestUrl(newUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved! Refreshing pack list...'),
            backgroundColor: Colors.green,
          ),
        );
        // Refetch the manifest with the new URL
        appState.fetchManifest();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No changes to save.')));
      }
    }
  }

  void _onRadioChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedUrlOption = value;
      // If a predefined URL is selected, update the text field.
      // If 'custom' is selected, the user can now edit the text field,
      // which retains its previous value for convenience.
      if (value != 'custom') {
        _urlController.text = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the custom text field should be enabled.
    final isCustomUrl = _selectedUrlOption == 'custom';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vocabulary Manifest URL',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a predefined source or enter a custom URL for the vocabulary pack list.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Generate RadioListTile for each predefined manifest
                  ...AppState.PREDEFINED_MANIFESTS.map((manifest) {
                    return RadioListTile<String>(
                      title: Text(manifest['name']!),
                      subtitle: Text(
                        manifest['url']!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      value: manifest['url']!,
                      groupValue: _selectedUrlOption,
                      onChanged: _onRadioChanged,
                    );
                  }),
                  // RadioListTile for the Custom URL option
                  RadioListTile<String>(
                    title: const Text('Custom URL'),
                    value: 'custom',
                    groupValue: _selectedUrlOption,
                    onChanged: _onRadioChanged,
                  ),
                  const SizedBox(height: 8),
                  // The TextFormField for the custom URL
                  TextFormField(
                    controller: _urlController,
                    enabled: isCustomUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Manifest URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/manifest.json',
                    ),
                    validator: (value) {
                      // Only validate if the custom option is selected.
                      if (isCustomUrl) {
                        if (value == null || value.trim().isEmpty) {
                          return 'URL cannot be empty.';
                        }
                        final uri = Uri.tryParse(value);
                        if (uri == null || !uri.isAbsolute) {
                          return 'Please enter a valid URL (e.g., https://...).';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save and Refresh Packs'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
