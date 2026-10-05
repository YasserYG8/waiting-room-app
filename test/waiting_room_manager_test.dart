import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/waiting_room_manager.dart';

void main() {
  test('should add a client to the waiting list', () {
    final manager = WaitingRoomManager();

    manager.addClient('Gombra Yasser');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Gombra Yasser');
  });

  test('should remove a client from the waiting list', () {
    final manager = WaitingRoomManager();
    manager.addClient('Gombra Yasser');
    manager.addClient('Gombra Yasser');

    manager.removeClient('Gombra Yasser');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Gombra Yasser');
  });
}
