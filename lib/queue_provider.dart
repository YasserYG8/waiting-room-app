import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/geolocation_service.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient _supabase;
  final LocalQueueService _localDb;
  final GeolocationService _geoService;
  RealtimeChannel? _channel;

  List<Client> _clients = [];
  List<Client> get clients => _clients;

  QueueProvider({
    SupabaseClient? supabase,
    LocalQueueService? localDb,
    GeolocationService? geoService,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _localDb = localDb ?? LocalQueueService(),
        _geoService = geoService ?? GeolocationService() {
    _loadQueue();
  }

  QueueProvider.forTesting(
    this._supabase, {
    LocalQueueService? localDb,
    GeolocationService? geoService,
  })  : _localDb = localDb ?? LocalQueueService(inMemory: true),
        _geoService = geoService ?? GeolocationService();

  Future<void> _loadQueue() async {
    final localData = await _localDb.getClients();
    _clients = localData.map(Client.fromMap).toList();
    notifyListeners();

    await _syncLocalToRemote();
    _setupRealtimeSubscription();
  }

  Future<void> _syncLocalToRemote() async {
    final unsynced = await _localDb.getUnsyncedClients();
    for (final clientMap in unsynced) {
      try {
        final remoteClient = Map<String, dynamic>.from(clientMap)..remove('is_synced');
        await _supabase.from('clients').upsert(remoteClient);
        await _localDb.markClientAsSynced(clientMap['id'] as String);
      } catch (_) {}
    }
    final refreshedData = await _localDb.getClients();
    _clients = refreshedData.map(Client.fromMap).toList();
    notifyListeners();
  }

  void _setupRealtimeSubscription() {
    _channel = _supabase
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) async {
            final newClient = Client.fromMap(payload.newRecord);
            await _localDb.insertClientLocally(newClient.toMap(includeSyncStatus: true));
            if (!_clients.any((c) => c.id == newClient.id)) {
              _clients.add(newClient);
              _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) async {
            final deletedId = payload.oldRecord['id'];
            final db = await _localDb.database;
            await db.delete(LocalQueueService.tableName, where: 'id = ?', whereArgs: [deletedId]);
            _clients.removeWhere((client) => client.id == deletedId);
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> addClient(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final position = await _geoService.getCurrentPosition();

    final newClient = Client(
      id: const Uuid().v4(),
      name: trimmedName,
      lat: position?.latitude,
      lng: position?.longitude,
      createdAt: DateTime.now(),
      isSynced: 0,
    );

    await _localDb.insertClientLocally(newClient.toMap(includeSyncStatus: true));

    _clients.add(newClient);
    _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();

    unawaited(_syncLocalToRemote());
  }

  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().match({'id': id});
    } catch (_) {}
    final db = await _localDb.database;
    await db.delete(LocalQueueService.tableName, where: 'id = ?', whereArgs: [id]);
    _clients.removeWhere((client) => client.id == id);
    notifyListeners();
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) return;
    final firstClient = _clients.first;
    await removeClient(firstClient.id);
  }

  @override
  void dispose() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
