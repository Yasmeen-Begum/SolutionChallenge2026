import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/providers/crisis_provider.dart';
import 'core/providers/comms_provider.dart';
import 'core/providers/personnel_provider.dart';
import 'core/services/demo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialisation – falls back to demo mode if not configured
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase unavailable – running in demo mode: $e');
  }

  // Seed demo data for standalone preview
  final demoService = DemoService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CrisisProvider(demoService: demoService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => CommsProvider(demoService: demoService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => PersonnelProvider(demoService: demoService)..init(),
        ),
      ],
      child: const CrisisSyncApp(),
    ),
  );
}
