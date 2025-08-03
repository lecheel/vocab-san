import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_jp/providers/app_state.dart';

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  @override
  void initState() {
    super.initState();
    // On start, fetch the manifest and scan for local files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.fetchManifest();
      appState.scanForLocalVocabulary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section for downloading new packs
              const Text("Available for Download", style: TextStyle(fontSize: 18)),
              const Divider(),
              if (appState.isLoading) const LinearProgressIndicator(),
              if (appState.statusMessage.isNotEmpty) Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(appState.statusMessage, textAlign: TextAlign.center),
              ),
              Expanded(
                flex: 2, // Give more space to the download list
                child: ListView.builder(
                  itemCount: appState.availablePacks.length,
                  itemBuilder: (context, index) {
                    final pack = appState.availablePacks[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_download_outlined),
                        title: Text('${pack.name} (v${pack.version})'),
                        subtitle: Text(pack.description),
                        onTap: appState.isLoading
                          ? null
                          : () => appState.downloadAndUnzipVocabulary(pack),
                      ),
                    );
                  },
                ),
              ),

              // Section for locally available files
              const SizedBox(height: 20),
              const Text("Downloaded Lists", style: TextStyle(fontSize: 18)),
              const Divider(),
              Expanded(
                flex: 1,
                child: appState.files.isEmpty
                  ? const Center(child: Text("No lists downloaded yet."))
                  : ListView.builder(
                    itemCount: appState.files.length,
                    itemBuilder: (context, index) {
                      final file = appState.files[index];
                      final isActive = file.path == appState.activeFilePath;
                      return Card(
                        color: isActive ? Colors.teal.withOpacity(0.3) : null,
                        child: ListTile(
                          leading: const Icon(Icons.description),
                          // Show a more readable name, like "n5_essentials/vocab.json"
                          title: Text(file.path.split('/').sublist(file.path.split('/').length - 2).join('/')),
                          onTap: () => appState.loadVocabulary(file),
                          selected: isActive,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
