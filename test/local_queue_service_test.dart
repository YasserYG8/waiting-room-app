import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:waiting_room_app/local_queue_service.dart';

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('insertClientLocally adds a record to the database', () async {
    final service = LocalQueueService(inMemory: true);
    await service.insertClientLocally({
      'id': 'test-123',
      'name': 'Alice',
      'lat': 40.71,
      'lng': -74.00,
      'created_at': '2024-01-01T00:00:00Z',
      'is_synced': 0,
    });

    final clients = await service.getUnsyncedClients();
    expect(clients.length, 1);
    expect(clients[0]['name'], 'Alice');
  });
}
