import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/waiting_room_card.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('WaitingRoomCard displays the name correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WaitingRoomCard(name: 'Alice'),
      ),
    );

    expect(find.text('Hello,'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });
}
