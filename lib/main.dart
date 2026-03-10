import 'package:flutter/material.dart';

import 'screens/project_list_screen.dart';

void main() {
  runApp(const LabPilotApp());
}

class LabPilotApp extends StatelessWidget {
  const LabPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);

    return MaterialApp(
      title: 'LabPilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF5F2E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFEDE7DA),
        useMaterial3: true,
      ),
      home: const ProjectListScreen(),
    );
  }
}
