import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Firebase stays optional for local/offline mode until platform configs are added.
  }

  runApp(const WorshipApp());
}
