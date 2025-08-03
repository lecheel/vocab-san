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

  @override
  void initState() {
    super.initState();
    // Initialize the controller with the current URL from AppState
    final initialUrl = Provider.of<AppState>(
      context,
      listen: false,
    ).manifestUrl;
    _urlController = TextEditingController(text: initialUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final newUrl = _urlController.text.trim();
      Provider.of<AppState>(context, listen: false).updateManifestUrl(newUrl);

      // Give user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved!'),
          backgroundColor: Colors.green,
        ),
      );
      // Refetch the manifest with the new URL
      Provider.of<AppState>(context, listen: false).fetchManifest();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vocabulary Manifest URL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The JSON file that lists all available vocabulary packs.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Manifest URL',
                        border: OutlineInputBorder(),
                        hintText: 'https://example.com/manifest.json',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'URL cannot be empty.';
                        }
                        // First, try to parse the URI.
                        final uri = Uri.tryParse(value);
                        // Check if parsing failed OR if the resulting URI is not absolute.
                        if (uri == null || !uri.isAbsolute) {
                          return 'Please enter a valid, absolute URL (e.g., starting with http:// or https://).';
                        }
                        // If we reach here, the URL is valid.
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
      ),
    );
  }
}
