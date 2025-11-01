import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  Database? _db;

  factory OfflineService() {
    return _instance;
  }

  OfflineService._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'smart_farming.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create command queue table
    await db.execute('''
      CREATE TABLE command_queue (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        command_type TEXT NOT NULL,
        params TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create sensor readings cache table
    await db.execute('''
      CREATE TABLE local_cache_sensor_readings (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        moisture REAL NOT NULL,
        temperature REAL NOT NULL,
        humidity REAL NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create notifications cache table
    await db.execute('''
      CREATE TABLE local_cache_notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Create indices
    await db.execute('''
      CREATE INDEX idx_command_device ON command_queue(device_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_command_status ON command_queue(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_sensor_device ON local_cache_sensor_readings(device_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_sensor_timestamp ON local_cache_sensor_readings(timestamp)
    ''');
  }

  // Command Queue Methods
  Future<void> queueCommand({
    required String commandId,
    required String deviceId,
    required String commandType,
    required Map<String, dynamic> params,
  }) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();

    await database.insert(
      'command_queue',
      {
        'id': commandId,
        'device_id': deviceId,
        'command_type': commandType,
        'params': _encodeParams(params),
        'status': 'pending',
        'retry_count': 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingCommands() async {
    final database = await db;
    return await database.query(
      'command_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> updateCommandStatus({
    required String commandId,
    required String status,
  }) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();

    await database.update(
      'command_queue',
      {
        'status': status,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [commandId],
    );
  }

  Future<void> incrementCommandRetry(String commandId) async {
    final database = await db;
    final now = DateTime.now().toIso8601String();

    await database.rawUpdate(
      '''
      UPDATE command_queue
      SET retry_count = retry_count + 1, updated_at = ?
      WHERE id = ?
      ''',
      [now, commandId],
    );
  }

  Future<void> deleteCommand(String commandId) async {
    final database = await db;
    await database.delete(
      'command_queue',
      where: 'id = ?',
      whereArgs: [commandId],
    );
  }

  // Sensor Readings Cache Methods
  Future<void> cacheSensorReading({
    required String deviceId,
    required double moisture,
    required double temperature,
    required double humidity,
  }) async {
    final database = await db;
    final id = '${deviceId}_${DateTime.now().millisecondsSinceEpoch}';

    await database.insert(
      'local_cache_sensor_readings',
      {
        'id': id,
        'device_id': deviceId,
        'moisture': moisture,
        'temperature': temperature,
        'humidity': humidity,
        'timestamp': DateTime.now().toIso8601String(),
        'synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCachedSensorReadings({
    required String deviceId,
    Duration? maxAge,
  }) async {
    final database = await db;
    String query = 'SELECT * FROM local_cache_sensor_readings WHERE device_id = ?';
    List<dynamic> args = [deviceId];

    if (maxAge != null) {
      final cutoffTime = DateTime.now().subtract(maxAge).toIso8601String();
      query += ' AND timestamp > ?';
      args.add(cutoffTime);
    }

    query += ' ORDER BY timestamp DESC LIMIT 288';  // Max 5-minute intervals for 24h

    return await database.rawQuery(query, args);
  }

  Future<void> markSensorReadingsSynced(List<String> readingIds) async {
    final database = await db;
    for (final id in readingIds) {
      await database.update(
        'local_cache_sensor_readings',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> clearOldSensorReadings({int olderThanDays = 2}) async {
    final database = await db;
    final cutoffTime = DateTime.now().subtract(Duration(days: olderThanDays));

    await database.delete(
      'local_cache_sensor_readings',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime.toIso8601String()],
    );
  }

  // Notifications Cache Methods
  Future<void> cacheNotification({
    required String notificationId,
    required String type,
    required String title,
    required String message,
  }) async {
    final database = await db;

    await database.insert(
      'local_cache_notifications',
      {
        'id': notificationId,
        'type': type,
        'title': title,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    final database = await db;
    return await database.query(
      'local_cache_notifications',
      orderBy: 'created_at DESC',
      limit: 50,
    );
  }

  Future<void> markNotificationsSynced(List<String> notificationIds) async {
    final database = await db;
    for (final id in notificationIds) {
      await database.update(
        'local_cache_notifications',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> clearOldNotifications({int olderThanDays = 30}) async {
    final database = await db;
    final cutoffTime = DateTime.now().subtract(Duration(days: olderThanDays));

    await database.delete(
      'local_cache_notifications',
      where: 'created_at < ?',
      whereArgs: [cutoffTime.toIso8601String()],
    );
  }

  // Helper methods
  String _encodeParams(Map<String, dynamic> params) {
    return params.toString();
  }

  Map<String, dynamic> _decodeParams(String params) {
    // Simple parsing - in production, use json
    return {};
  }

  Future<void> clearAllCache() async {
    final database = await db;
    await database.delete('command_queue');
    await database.delete('local_cache_sensor_readings');
    await database.delete('local_cache_notifications');
  }
}
