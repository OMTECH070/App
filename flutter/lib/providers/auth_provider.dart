import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _secureStorage = const FlutterSecureStorage();
  final _apiService = ApiService();

  String? _accessToken;
  String? _refreshToken;
  String? _userId;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isAuthenticated => _accessToken != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userId => _userId;

  // Initialize - Check if user already logged in
  Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    _userId = await _secureStorage.read(key: 'user_id');

    if (_accessToken != null) {
      _apiService.setTokens(_accessToken, _refreshToken);
    }

    notifyListeners();
  }

  // Register
  Future<bool> register({
    required String email,
    required String phone,
    required String password,
    required String name,
    required String language,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        phone: phone,
        password: password,
        name: name,
        language: language,
      );

      _accessToken = response['access_token'];
      _refreshToken = response['refresh_token'];
      _userId = response['user_id'] ?? 'unknown';

      // Store tokens securely
      await _secureStorage.write(key: 'access_token', value: _accessToken!);
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken!);
      await _secureStorage.write(key: 'user_id', value: _userId!);

      _apiService.setTokens(_accessToken, _refreshToken);

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

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _accessToken = response['access_token'];
      _refreshToken = response['refresh_token'];
      _userId = response['user_id'] ?? 'unknown';

      // Store tokens securely
      await _secureStorage.write(key: 'access_token', value: _accessToken!);
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken!);
      await _secureStorage.write(key: 'user_id', value: _userId!);

      _apiService.setTokens(_accessToken, _refreshToken);

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

  // Logout
  Future<void> logout() async {
    try {
      // Call logout endpoint
      if (_refreshToken != null) {
        await _apiService.logout(refreshToken: _refreshToken!);
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Clear local data
      _accessToken = null;
      _refreshToken = null;
      _userId = null;
      _error = null;

      // Clear secure storage
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_id');

      _apiService.clearTokens();
      notifyListeners();
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      _error = 'No refresh token available';
      return false;
    }

    try {
      final response = await _apiService.refreshToken(refreshToken: _refreshToken!);

      _accessToken = response['access_token'];
      _refreshToken = response['refresh_token'];

      // Store updated tokens
      await _secureStorage.write(key: 'access_token', value: _accessToken!);
      await _secureStorage.write(key: 'refresh_token', value: _refreshToken!);

      _apiService.setTokens(_accessToken, _refreshToken);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
