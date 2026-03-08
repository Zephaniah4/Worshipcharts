import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'features/integrations/integrations_screen.dart';
import 'features/setlists/setlists_screen.dart';
import 'features/songs/songs_screen.dart';

class WorshipApp extends StatelessWidget {
  const WorshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: AppState.create(),
      builder: (BuildContext context, AsyncSnapshot<AppState> snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            title: 'Worship Chords',
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
            ),
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return ChangeNotifierProvider<AppState>.value(
          value: snapshot.data!,
          child: MaterialApp(
            title: 'Worship Chords',
            theme: ThemeData(
              colorSchemeSeed: Colors.blue,
              useMaterial3: true,
            ),
            home: const _HomeShell(),
          ),
        );
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    final List<Widget> pages = <Widget>[
      const SongsScreen(),
      const SetlistsScreen(),
      const IntegrationsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final int flushed = await state.flushPendingSync();
          if (!context.mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Flushed $flushed queued operations to backend.')),
          );
        },
        label: const Text('Sync Now'),
        icon: const Icon(Icons.sync),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) {
          setState(() => _index = value);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.library_music), label: 'Songs'),
          NavigationDestination(icon: Icon(Icons.queue_music), label: 'Setlists'),
          NavigationDestination(icon: Icon(Icons.hub), label: 'Integrations'),
        ],
      ),
    );
  }
}
