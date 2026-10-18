import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/models/client.dart';

class QueueProvider extends ChangeNotifier {
  final List<Client> _clients = [];
  List<Client> get clients => _clients;

  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  QueueProvider() : _supabase = Supabase.instance.client {
    _fetchInitialClients();
    _setupRealtimeSubscription();
  }

  QueueProvider.forTesting(this._supabase) : super();

  Future<void> _fetchInitialClients() async {
    try {
      final data = await _supabase
          .from('clients')
          .select()
          .order('created_at');
      _clients.clear();
      _clients.addAll(
        (data as List).map((item) => Client.fromMap(item as Map<String, dynamic>)),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching clients: $e');
    }
  }

  void _setupRealtimeSubscription() {
    _channel = _supabase
        .channel('public:clients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final newClient = Client.fromMap(payload.newRecord);
            _clients.add(newClient);
            _clients.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            notifyListeners();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'clients',
          callback: (payload) {
            final deletedId = payload.oldRecord['id'];
            _clients.removeWhere((client) => client.id == deletedId);
            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> addClient(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      debugPrint('Cannot add empty client name');
      return;
    }
    try {
      await _supabase.from('clients').insert({'name': trimmedName});
      debugPrint('Client added: $trimmedName');
    } catch (e) {
      debugPrint('Failed to add client: $e');
    }
  }

  Future<void> removeClient(String id) async {
    try {
      await _supabase.from('clients').delete().match({'id': id});
      debugPrint('Client removed: $id');
    } catch (e) {
      debugPrint('Failed to remove client: $e');
    }
  }

  Future<void> nextClient() async {
    if (_clients.isEmpty) {
      debugPrint('Queue is empty!');
      return;
    }
    final firstClient = _clients.first;
    await removeClient(firstClient.id);
    debugPrint('Next client: ${firstClient.name}');
  }

  @override
  void dispose() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
