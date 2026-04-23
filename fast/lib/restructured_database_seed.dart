import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast/firebase_options.dart';
import 'package:fast/scripts/restructured_database_seeder.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

const bool _dryRun = bool.fromEnvironment('DRY_RUN', defaultValue: false);
const bool _seedExamples =
    bool.fromEnvironment('SEED_EXAMPLES', defaultValue: true);
const bool _seedQuickLinks =
    bool.fromEnvironment('SEED_QUICK_LINKS', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final seeder = RestructuredDatabaseSeeder(
      firestore: FirebaseFirestore.instance,
      now: DateTime.now(),
      dryRun: _dryRun,
      seedExamples: _seedExamples,
      seedQuickLinks: _seedQuickLinks,
    );

    await seeder.run();
    exit(0);
  } catch (error, stackTrace) {
    stderr.writeln('Failed to seed restructured FAST database: $error');
    stderr.writeln(stackTrace);
    exit(1);
  }
}
