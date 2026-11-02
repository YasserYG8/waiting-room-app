// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/queue_provider.dart';

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  Map<String, Object>? lastMatched;

  @override
  PostgrestFilterBuilder<dynamic> match(Map<String, Object> query) {
    lastMatched = query;
    return this;
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue, {Function? onError}) {
    return Future<dynamic>.value([]).then(onValue, onError: onError);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  Object? lastUpserted;
  bool deleteCalled = false;
  final FakePostgrestFilterBuilder filterBuilder = FakePostgrestFilterBuilder();

  @override
  PostgrestFilterBuilder<dynamic> upsert(Object values, {String? onConflict, bool ignoreDuplicates = false, bool defaultToNull = true}) {
    lastUpserted = values;
    return filterBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> delete({PostgrestBuilder? count}) {
    deleteCalled = true;
    return filterBuilder;
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  String? fromTable;
  final FakeSupabaseQueryBuilder queryBuilder = FakeSupabaseQueryBuilder();

  @override
  SupabaseQueryBuilder from(String table) {
    fromTable = table;
    return queryBuilder;
  }
}

class FakeGeolocationService extends Fake implements GeolocationService {
  @override
  Future<Position?> getCurrentPosition() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('addClient saves client locally and triggers sync', () async {
    final fakeClient = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);
    final fakeGeo = FakeGeolocationService();
    final provider = QueueProvider.forTesting(
      fakeClient,
      localDb: localDb,
      geoService: fakeGeo,
    );

    await provider.addClient('Alice');

    expect(provider.clients.length, 1);
    expect(provider.clients.first.name, 'Alice');
  });

  test('addClient does not add when name is empty', () async {
    final fakeClient = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);
    final fakeGeo = FakeGeolocationService();
    final provider = QueueProvider.forTesting(
      fakeClient,
      localDb: localDb,
      geoService: fakeGeo,
    );

    await provider.addClient('   ');

    expect(provider.clients.isEmpty, isTrue);
  });

  test('removeClient removes from provider and calls delete', () async {
    final fakeClient = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);
    final fakeGeo = FakeGeolocationService();
    final provider = QueueProvider.forTesting(
      fakeClient,
      localDb: localDb,
      geoService: fakeGeo,
    );

    await provider.addClient('Alice');
    final id = provider.clients.first.id;

    await provider.removeClient(id);

    expect(provider.clients.isEmpty, isTrue);
    expect(fakeClient.fromTable, 'clients');
    expect(fakeClient.queryBuilder.deleteCalled, isTrue);
    expect(fakeClient.queryBuilder.filterBuilder.lastMatched, {'id': id});
  });

  test('nextClient does not call delete when queue is empty', () async {
    final fakeClient = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);
    final fakeGeo = FakeGeolocationService();
    final provider = QueueProvider.forTesting(
      fakeClient,
      localDb: localDb,
      geoService: fakeGeo,
    );

    await provider.nextClient();

    expect(fakeClient.queryBuilder.deleteCalled, isFalse);
  });
}
