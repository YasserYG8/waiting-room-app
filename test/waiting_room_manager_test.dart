import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/waiting_room_manager.dart';

void main() {
  test('should add a client to the waiting list', () {
    final manager = WaitingRoomManager();

    manager.addClient('John Doe');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'John Doe');
  });

  test('should remove a client from the waiting list', () {
    final manager = WaitingRoomManager();
    manager.addClient('John Doe');
    manager.addClient('Jane Doe');

    manager.removeClient('John Doe');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Jane Doe');
  });
}
