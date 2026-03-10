import 'package:flutter_test/flutter_test.dart';
import 'package:labpilot_client/main.dart';

void main() {
  testWidgets('renders LabPilot shell', (tester) async {
    await tester.pumpWidget(const LabPilotApp());

    expect(find.text('LabPilot Installable Client'), findsOneWidget);
    expect(find.text('One client for desktop, tablet, and phone.'), findsOneWidget);
    expect(find.text('Backend base URL'), findsOneWidget);
  });
}
