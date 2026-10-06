import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
  test('should add a client to the waiting list', () {
    final manager = QueueProvider();

    manager.addClient('Gombra Yasser');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Gombra Yasser');
  });

  test('should remove a client from the waiting list', () {
    final manager = QueueProvider();
    manager.addClient('Gombra Yasser');
    manager.addClient('Gombra Yasser');

    manager.removeClient('Gombra Yasser');

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Gombra Yasser');
  });

  test('should remove the first client when nextClient is called', () {
    final manager = QueueProvider();
    manager.addClient('Client A');
    manager.addClient('Client B');

    manager.nextClient();

    expect(manager.clients.length, 1);
    expect(manager.clients.first, 'Client B');
  });
}
