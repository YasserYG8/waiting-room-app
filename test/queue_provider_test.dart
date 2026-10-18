// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Object? lastInserted;
  bool deleteCalled = false;
  final FakePostgrestFilterBuilder filterBuilder = FakePostgrestFilterBuilder();

  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = true}) {
    lastInserted = values;
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

void main() {
  test('addClient calls insert with client name', () async {
    final fakeClient = FakeSupabaseClient();
    final provider = QueueProvider.forTesting(fakeClient);

    await provider.addClient('Alice');

    expect(fakeClient.fromTable, 'clients');
    expect(fakeClient.queryBuilder.lastInserted, {'name': 'Alice'});
  });

  test('addClient does not call insert when name is empty', () async {
    final fakeClient = FakeSupabaseClient();
    final provider = QueueProvider.forTesting(fakeClient);

    await provider.addClient('   ');

    expect(fakeClient.fromTable, isNull);
    expect(fakeClient.queryBuilder.lastInserted, isNull);
  });

  test('removeClient calls delete matching id', () async {
    final fakeClient = FakeSupabaseClient();
    final provider = QueueProvider.forTesting(fakeClient);

    await provider.removeClient('client-uuid-123');

    expect(fakeClient.fromTable, 'clients');
    expect(fakeClient.queryBuilder.deleteCalled, isTrue);
    expect(fakeClient.queryBuilder.filterBuilder.lastMatched, {'id': 'client-uuid-123'});
  });

  test('nextClient does not call delete when queue is empty', () async {
    final fakeClient = FakeSupabaseClient();
    final provider = QueueProvider.forTesting(fakeClient);

    await provider.nextClient();

    expect(fakeClient.queryBuilder.deleteCalled, isFalse);
  });
}
