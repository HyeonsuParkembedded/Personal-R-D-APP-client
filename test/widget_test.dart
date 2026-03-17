import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labpilot_client/main.dart';

void main() {
  testWidgets('renders LabPilot shell', (tester) async {
    await tester.pumpWidget(const LabPilotApp());
    await tester.pump();

    expect(find.text('LabPilot Projects'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
