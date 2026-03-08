import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({super.key});

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _keyController = TextEditingController(text: 'C');
  final TextEditingController _lyricsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _keyController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Song')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            TextField(
              controller: _keyController,
              decoration: const InputDecoration(labelText: 'Key'),
            ),
            TextField(
              controller: _lyricsController,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Lyrics + Chords',
                hintText: 'Example: [C]Amazing [G]grace...',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (_titleController.text.trim().isEmpty) {
                  return;
                }
                await context.read<AppState>().addSong(
                      title: _titleController.text.trim(),
                      artist: _artistController.text.trim(),
                      key: _keyController.text.trim().isEmpty ? 'C' : _keyController.text.trim(),
                      lyricsWithChords: _lyricsController.text,
                    );
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save Song'),
            ),
          ],
        ),
      ),
    );
  }
}
