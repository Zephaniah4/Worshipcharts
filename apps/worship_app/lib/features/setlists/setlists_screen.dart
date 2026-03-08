import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/setlist.dart';
import '../../models/song.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends State<SetlistsScreen> {
  final TextEditingController _setlistNameController = TextEditingController();

  @override
  void dispose() {
    _setlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _setlistNameController,
                    decoration: const InputDecoration(labelText: 'New setlist name'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    if (_setlistNameController.text.trim().isEmpty) {
                      return;
                    }
                    await state.createSetlist(
                      name: _setlistNameController.text.trim(),
                      teamId: 'default-team',
                    );
                    _setlistNameController.clear();
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: state.setlists.length,
              itemBuilder: (BuildContext context, int index) {
                final Setlist setlist = state.setlists[index];
                return _SetlistCard(setlist: setlist);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SetlistCard extends StatelessWidget {
  const _SetlistCard({required this.setlist});

  final Setlist setlist;
  static const List<String> _permissions = <String>['view', 'edit', 'manage'];

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(setlist.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Songs in setlist: ${setlist.songIds.length}'),
            Text('Collaborators: ${setlist.shares.length}'),
            const SizedBox(height: 8),
            if (state.songs.isNotEmpty)
              DropdownButton<String>(
                hint: const Text('Add song to setlist'),
                value: null,
                items: state.songs
                    .map(
                      (Song song) => DropdownMenuItem<String>(
                        value: song.id,
                        child: Text(song.title),
                      ),
                    )
                    .toList(),
                onChanged: (String? songId) async {
                  if (songId == null) {
                    return;
                  }
                  await state.addSongToSetlist(setlistId: setlist.id, songId: songId);
                },
              )
            else
              const Text('Create songs first to add them here.'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext sheetContext) {
                      return _SetlistShareSheet(setlist: setlist);
                    },
                  );
                },
                icon: const Icon(Icons.group_add),
                label: const Text('Manage Sharing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetlistShareSheet extends StatefulWidget {
  const _SetlistShareSheet({required this.setlist});

  final Setlist setlist;

  @override
  State<_SetlistShareSheet> createState() => _SetlistShareSheetState();
}

class _SetlistShareSheetState extends State<_SetlistShareSheet> {
  final TextEditingController _collaboratorController = TextEditingController();
  String _selectedPermission = 'view';

  @override
  void dispose() {
    _collaboratorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final Setlist latest = state.setlists.firstWhere(
      (Setlist value) => value.id == widget.setlist.id,
      orElse: () => widget.setlist,
    );
    final List<MapEntry<String, String>> shares = latest.shares.entries.toList()
      ..sort((MapEntry<String, String> a, MapEntry<String, String> b) => a.key.compareTo(b.key));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Share "${latest.name}"', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _collaboratorController,
            decoration: const InputDecoration(
              labelText: 'Collaborator email or ID',
              hintText: 'Ex: teammember@example.com',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedPermission,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'view', child: Text('View')),
              DropdownMenuItem<String>(value: 'edit', child: Text('Edit')),
              DropdownMenuItem<String>(value: 'manage', child: Text('Manage')),
            ],
            decoration: const InputDecoration(labelText: 'Permission'),
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedPermission = value;
              });
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final String collaborator = _collaboratorController.text.trim();
              if (collaborator.isEmpty) {
                return;
              }
              await state.shareSetlist(
                setlistId: latest.id,
                collaborator: collaborator,
                permission: _selectedPermission,
              );
              _collaboratorController.clear();
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Shared with $collaborator as $_selectedPermission.')),
              );
            },
            child: const Text('Add / Update Collaborator'),
          ),
          const SizedBox(height: 12),
          Text('Current access', style: Theme.of(context).textTheme.titleSmall),
          if (shares.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('No collaborators yet.'),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: shares.length,
                itemBuilder: (BuildContext context, int index) {
                  final MapEntry<String, String> entry = shares[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.key),
                    subtitle: Text('Permission: ${entry.value}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DropdownButton<String>(
                          value: entry.value,
                          items: _SetlistCard._permissions
                              .map(
                                (String permission) => DropdownMenuItem<String>(
                                  value: permission,
                                  child: Text(permission),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) async {
                            if (value == null) {
                              return;
                            }
                            await state.shareSetlist(
                              setlistId: latest.id,
                              collaborator: entry.key,
                              permission: value,
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () async {
                            await state.removeSetlistShare(
                              setlistId: latest.id,
                              collaborator: entry.key,
                            );
                          },
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove collaborator',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
