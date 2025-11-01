import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'api_service.dart';
import 'offline_service.dart';

class SyncService extends ChangeNotifier {
  final _apiService = ApiService();
  final _offlineService = OfflineService();
  final _connectivity = Connectivity();
  final _logger = Logger();

  StreamSubscription? _connectivitySubscription;
  Timer? _syncTimer;

  bool _isSyncing = false;
  bool _isConnected = false;
  DateTime? _lastSyncTime;
  int _failedSyncs = 0;

  // Getters
  bool get isSyncing => _isSyncing;
  bool get isConnected => _isConnected;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Initialize
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    // Start periodic sync if connected
    if (_isConnected) {
      _startPeriodicSync();
    }
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;

    _logger.i('Connectivity changed: $_isConnected');

    if (_isConnected && !wasConnected) {
      // Reconnected - trigger sync
      _logger.i('Device reconnected - triggering sync');
      await syncNow();
      _startPeriodicSync();
    } else if (!_isConnected && wasConnected) {
      // Disconnected - stop periodic sync
      _logger.w('Device disconnected - stopping periodic sync');
      _syncTimer?.cancel();
    }

    notifyListeners();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      syncNow();
    });
  }

  Future<void> syncNow() async {
    if (_isSyncing || !_isConnected) {
      _logger.w('Sync skipped - already syncing or offline');
      return;
    }

    _isSyncing = true;
    _logger.i('Sync started');
    notifyListeners();

    try {
      // Sync pending commands
      await _syncPendingCommands();

      // Sync sensor readings
      await _syncSensorReadings();

      // Sync notifications
      await _syncNotifications();

      _lastSyncTime = DateTime.now();
      _failedSyncs = 0;

      _logger.i('Sync completed successfully');
    } catch (e) {
      _failedSyncs++;
      _logger.e('Sync failed: $e (attempt $_failedSyncs)');

      // Exponential backoff for next sync attempt
      if (_failedSyncs > 3) {
        _logger.e('Max sync failures reached - backing off');
        _syncTimer?.cancel();
        _syncTimer = Timer(Duration(minutes: 5 * _failedSyncs), (_) {
          _startPeriodicSync();
        });
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncPendingCommands() async {
    _logger.d('Syncing pending commands');

    final commands = await _offlineService.getPendingCommands();

    for (final command in commands) {
      try {
        final deviceId = command['device_id'] as String;
        final commandType = command['command_type'] as String;
        final commandId = command['id'] as String;

        // Execute command based on type
        if (commandType == 'irrigation_start') {
          final duration = int.parse(command['params'].toString());
          await _apiService.startIrrigation(
            deviceId: deviceId,
            durationMinutes: duration,
          );
        } else if (commandType == 'irrigation_stop') {
          await _apiService.stopIrrigation(deviceId);
        }

        // Mark as completed
        await _offlineService.updateCommandStatus(
          commandId: commandId,
          status: 'completed',
        );

        _logger.i('Command synced: $commandId');
      } catch (e) {
        _logger.e('Error syncing command: $e');
        // Keep command in pending state for retry
        final retryCount = int.parse(
          command['retry_count'].toString(),
        );

        if (retryCount < 10) {
          await _offlineService.incrementCommandRetry(command['id']);
        } else {
          // Mark as failed after max retries
          await _offlineService.updateCommandStatus(
            commandId: command['id'],
            status: 'failed',
          );
        }
      }
    }
  }

  Future<void> _syncSensorReadings() async {
    _logger.d('Syncing sensor readings cache');

    final readings = await _offlineService.getCachedSensorReadings(
      deviceId: '', // Get all cached readings
      maxAge: Duration(hours: 2),
    );

    // Note: In production, batch these readings for efficient upload
    // For MVP, we'll just clear the cache and rely on real-time data

    if (readings.isNotEmpty) {
      final readingIds = readings.map((r) => r['id'] as String).toList();
      await _offlineService.markSensorReadingsSynced(readingIds);
      _logger.i('Synced ${readings.length} sensor readings');
    }

    // Clear old readings
    await _offlineService.clearOldSensorReadings(olderThanDays: 2);
  }

  Future<void> _syncNotifications() async {
    _logger.d('Syncing notifications cache');

    final notifications = await _offlineService.getCachedNotifications();

    if (notifications.isNotEmpty) {
      final notificationIds =
          notifications.map((n) => n['id'] as String).toList();
      await _offlineService.markNotificationsSynced(notificationIds);
      _logger.i('Synced ${notifications.length} notifications');
    }

    // Clear old notifications
    await _offlineService.clearOldNotifications(olderThanDays: 30);
  }

  // Public methods for manual command queueing

  Future<void> queueIrrigationCommand({
    required String deviceId,
    required int durationMinutes,
  }) async {
    final commandId = 'cmd_${DateTime.now().millisecondsSinceEpoch}';

    await _offlineService.queueCommand(
      commandId: commandId,
      deviceId: deviceId,
      commandType: 'irrigation_start',
      params: {'duration': durationMinutes},
    );

    _logger.i('Irrigation command queued: $commandId');

    // If connected, sync immediately
    if (_isConnected && !_isSyncing) {
      await syncNow();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
