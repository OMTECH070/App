import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class DeviceProvider with ChangeNotifier {
  final _apiService = ApiService();

  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all devices
  Future<void> fetchDevices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getDevices();
      _devices = List<Map<String, dynamic>>.from(response['devices'] ?? []);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Pair device
  Future<bool> pairDevice({
    required String deviceId,
    required String fieldName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.pairDevice(
        deviceId: deviceId,
        fieldName: fieldName,
      );
      await fetchDevices();  // Refresh list
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete device
  Future<bool> deleteDevice(String deviceId) async {
    try {
      await _apiService.deleteDevice(deviceId);
      await fetchDevices();  // Refresh list
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get device status
  Future<Map<String, dynamic>?> getDeviceStatus(String deviceId) async {
    try {
      return await _apiService.getDeviceStatus(deviceId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
