// ignore_for_file: must_be_immutable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/geolocation_service.dart';
import 'package:waiting_room_app/local_queue_service.dart';
import 'package:waiting_room_app/main.dart';
import 'package:waiting_room_app/models/client.dart';
import 'package:waiting_room_app/queue_provider.dart';

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> match(Map<String, Object> query) => this;

  @override
  Future<R> then<R>(FutureOr<R> Function(dynamic value) onValue, {Function? onError}) {
    return Future<dynamic>.value([]).then(onValue, onError: onError);
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<dynamic> insert(Object values, {bool defaultToNull = true}) {
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<dynamic> upsert(Object values, {String? onConflict, bool ignoreDuplicates = false, bool defaultToNull = true}) {
    return FakePostgrestFilterBuilder();
  }

  @override
  PostgrestFilterBuilder<dynamic> delete({PostgrestBuilder? count}) {
    return FakePostgrestFilterBuilder();
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeSupabaseQueryBuilder queryBuilder = FakeSupabaseQueryBuilder();

  @override
  SupabaseQueryBuilder from(String table) => queryBuilder;
}

class FakeGeolocationService extends Fake implements GeolocationService {
  final Position? position;

  FakeGeolocationService({this.position});

  @override
  Future<Position?> getCurrentPosition() async => position;
}

void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('addClient saves client with geolocation', () async {
    final mockPos = Position(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    final fakeGeo = FakeGeolocationService(position: mockPos);
    final fakeSupabase = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);

    final provider = QueueProvider.forTesting(
      fakeSupabase,
      localDb: localDb,
      geoService: fakeGeo,
    );

    await provider.addClient('Test User');

    final client = provider.clients.last;
    expect(client.lat, 37.7749);
    expect(client.lng, -122.4194);
  });

  testWidgets('Displays location when available', (tester) async {
    final fakeSupabase = FakeSupabaseClient();
    final localDb = LocalQueueService(inMemory: true);
    final provider = QueueProvider.forTesting(fakeSupabase, localDb: localDb);

    final client = Client(
      id: '1',
      name: 'Sam',
      lat: 51.5074,
      lng: -0.1278,
      createdAt: DateTime.now(),
    );
    provider.clients.add(client);

    await tester.pumpWidget(
      ChangeNotifierProvider<QueueProvider>.value(
        value: provider,
        child: const MaterialApp(home: WaitingRoomScreen()),
      ),
    );

    expect(find.text('Sam'), findsOneWidget);
    expect(find.textContaining('51.5074'), findsOneWidget);
  });
}
