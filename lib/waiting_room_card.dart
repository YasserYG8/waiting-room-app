import 'package:flutter/material.dart';
import 'package:waiting_room_app/waiting_room_timestamp.dart';

class WaitingRoomCard extends StatelessWidget {
  final String name;

  const WaitingRoomCard({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hello,',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const WaitingRoomTimestamp(),
          ],
        ),
      ),
    );
  }
}
