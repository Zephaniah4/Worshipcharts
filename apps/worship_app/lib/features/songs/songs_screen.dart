import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/song.dart';
import 'song_editor_screen.dart';

class SongsScreen extends StatelessWidget {
  const SongsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SongEditorScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add song',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: state.songs.length,
        itemBuilder: (BuildContext context, int index) {
          final Song song = state.songs[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(song.title),
              subtitle: Text('${song.artist} | Key: ${song.currentKey}'),
              trailing: Wrap(
                spacing: 8,
                children: <Widget>[
                  IconButton(
                    onPressed: () async => state.transposeSong(song.id, -1),
                    icon: const Icon(Icons.remove),
                    tooltip: 'Transpose down',
                  ),
                  IconButton(
                    onPressed: () async => state.transposeSong(song.id, 1),
                    icon: const Icon(Icons.add),
                    tooltip: 'Transpose up',
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Pending sync operations: ${state.pendingSyncCount}'),
      ),
    );
  }
}
