import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labpilot_client/main.dart';
import 'package:labpilot_client/screens/settings_screen.dart';

void main() {
  testWidgets('renders LabPilot shell with AppBar', (tester) async {
    await tester.pumpWidget(const LabPilotApp());
    await tester.pump();

    expect(find.text('LabPilot Projects'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('FAB is present on project list screen', (tester) async {
    await tester.pumpWidget(const LabPilotApp());
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('settings screen renders AppBar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pump();

    expect(find.text('API 토큰 설정'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
