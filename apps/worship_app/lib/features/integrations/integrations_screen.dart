import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _importQueryController = TextEditingController();
  final TextEditingController _planIdController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _importQueryController.dispose();
    _planIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Integrations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          if (!state.backendConfigured)
            const Text('Firebase not configured. Add Firebase platform config files to enable cloud sync.')
          else ...<Widget>[
            if (state.isAuthenticated)
              Text('Signed in as ${state.currentUserEmail ?? 'user'}')
            else
              const Text('Sign in to enable automatic cloud sync across devices.'),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: () async {
                    final String message = await state.signIn(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  },
                  child: const Text('Sign In'),
                ),
                FilledButton.tonal(
                  onPressed: () async {
                    final String message = await state.signUp(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  },
                  child: const Text('Sign Up'),
                ),
                OutlinedButton(
                  onPressed: state.isAuthenticated
                      ? () async {
                          await state.signOut();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out.')),
                          );
                        }
                      : null,
                  child: const Text('Sign Out'),
                ),
                OutlinedButton(
                  onPressed: state.isAuthenticated
                      ? () async {
                          final int pulled = await state.pullRemoteChanges();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pulled $pulled remote changes.')),
                          );
                        }
                      : null,
                  child: const Text('Pull Remote'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Song Import', style: Theme.of(context).textTheme.titleMedium),
          TextField(
            controller: _importQueryController,
            decoration: const InputDecoration(
              labelText: 'Song title or URL',
              hintText: 'Ex: Amazing Grace',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed: () async {
                  await state.queueSongImport('songselect', _importQueryController.text.trim());
                },
                child: const Text('Queue SongSelect Import'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await state.queueSongImport('ultimate_guitar', _importQueryController.text.trim());
                },
                child: const Text('Queue Ultimate Guitar Import'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Planning Center', style: Theme.of(context).textTheme.titleMedium),
          TextField(
            controller: _planIdController,
            decoration: const InputDecoration(labelText: 'Planning Center Plan ID'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final String result = await state.pullPlanningCenterPlan(_planIdController.text.trim());
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
            },
            child: const Text('Pull Plan'),
          ),
          const SizedBox(height: 24),
          Text('Queued Imports: ${state.importQueueCount}'),
          const SizedBox(height: 24),
          Text('Test Mode', style: Theme.of(context).textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Simulate network available'),
            value: state.isNetworkAvailable,
            onChanged: state.setNetworkAvailable,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonal(
                onPressed: () async {
                  await state.addTestOperation();
                },
                child: const Text('Queue Test Operation'),
              ),
              FilledButton(
                onPressed: () async {
                  final int flushed = await state.flushPendingSync();
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Flushed $flushed operations')),
                  );
                },
                child: const Text('Flush Queue'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Pending sync queue: ${state.pendingSyncCount}'),
        ],
      ),
    );
  }
}
