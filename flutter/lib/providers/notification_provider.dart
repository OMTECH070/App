import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final _apiService = ApiService();

  List<Map<String, dynamic>> _notifications = [];
  int _totalNotifications = 0;
  bool _isLoading = false;
  String? _error;
  String _filterType = 'all';  // all, critical, warning, info, success

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  int get totalNotifications => _totalNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterType => _filterType;

  // Get notifications
  Future<void> fetchNotifications({
    int limit = 50,
    int offset = 0,
    String type = 'all',
  }) async {
    _isLoading = true;
    _error = null;
    _filterType = type;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(
        limit: limit,
        offset: offset,
        type: type,
      );
      _notifications = List<Map<String, dynamic>>.from(response['notifications'] ?? []);
      _totalNotifications = response['total'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      // Update local list
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _apiService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _totalNotifications--;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
