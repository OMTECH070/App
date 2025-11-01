import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SensorProvider with ChangeNotifier {
  final _apiService = ApiService();

  Map<String, dynamic>? _latestReading;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get latestReading => _latestReading;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get latest sensor reading
  Future<void> fetchLatestReading(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _latestReading = await _apiService.getLatestSensorReading(deviceId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get sensor history
  Future<void> fetchHistory({
    required String deviceId,
    required int hours,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSensorHistory(
        deviceId: deviceId,
        hours: hours,
      );
      _history = List<Map<String, dynamic>>.from(response['readings'] ?? []);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
