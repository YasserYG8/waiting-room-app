class Client {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  final int isSynced;

  Client({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    required this.createdAt,
    this.isSynced = 0,
  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      createdAt: map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap({bool includeSyncStatus = false}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
    };
    if (includeSyncStatus) {
      map['is_synced'] = isSynced;
    }
    return map;
  }

  @override
  String toString() =>
      'Client(id: $id, name: $name, lat: $lat, lng: $lng, created_at: $createdAt, isSynced: $isSynced)';
}
