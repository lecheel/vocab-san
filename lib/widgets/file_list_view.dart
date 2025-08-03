import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:vocab_jp/providers/app_state.dart'; // Corrected import

class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  bool _isDragging = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
      if (mounted) {
        await Provider.of<AppState>(context, listen: false).addFiles(files);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return DropTarget(
          onDragDone: (detail) async {
            final files = detail.files.map((f) => File(f.path)).toList();
            await appState.addFiles(files);
          },
          onDragEntered: (detail) => setState(() => _isDragging = true),
          onDragExited: (detail) => setState(() => _isDragging = false),
          child: Container(
            color: _isDragging ? Colors.teal.withOpacity(0.4) : null,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFiles,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Files (Ctrl+O)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Loaded Files", style: TextStyle(fontSize: 18)),
                const Divider(),
                if (appState.isLoading && appState.files.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (appState.files.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Drag and drop JSON files here\nor click the button above.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: appState.files.length,
                      itemBuilder: (context, index) {
                        final file = appState.files[index];
                        final isActive = file.path == appState.activeFilePath;
                        return Card(
                          color: isActive ? Colors.teal.withOpacity(0.3) : null,
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(
                              file.path.split(Platform.pathSeparator).last,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(file.parent.path),
                            onTap: () => appState.loadVocabulary(file),
                            selected: isActive,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
