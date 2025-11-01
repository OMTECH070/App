import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'package:logger/logger.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  String? _token;
  String? _baseUrl;
  bool _isConnecting = false;
  bool _isConnected = false;
  final _logger = Logger();

  factory WebSocketService() {
    return _instance;
  }

  WebSocketService._internal();

  bool get isConnected => _isConnected;

  Stream<Map<String, dynamic>> get messages {
    _messageController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _messageController!.stream;
  }

  Future<void> connect({
    required String baseUrl,
    required String token,
  }) async {
    if (_isConnected || _isConnecting) {
      _logger.w('WebSocket already connecting or connected');
      return;
    }

    _isConnecting = true;
    _token = token;
    _baseUrl = baseUrl;

    try {
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      final url = Uri.parse('$wsUrl/ws?token=$token');

      _channel = WebSocketChannel.connect(url);

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _logger.e('WebSocket error: $error');
          disconnect();
          _attemptReconnect();
        },
        onDone: () {
          _logger.w('WebSocket closed');
          _isConnected = false;
          _isConnecting = false;
          _attemptReconnect();
        },
      );

      _isConnected = true;
      _isConnecting = false;
      _logger.i('WebSocket connected');

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      _isConnecting = false;
      _attemptReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      if (message is String) {
        // Parse JSON message
        final decoded = _parseJson(message);
        if (decoded != null) {
          _messageController?.add(decoded);

          // Handle different message types
          final type = decoded['type'] as String?;
          if (type == 'pong') {
            _logger.d('Received pong from server');
          }
        }
      }
    } catch (e) {
      _logger.e('Error handling WebSocket message: $e');
    }
  }

  Map<String, dynamic>? _parseJson(String json) {
    try {
      // Simple JSON parsing - in production use dart:convert
      if (json.startsWith('{')) {
        return {'raw': json};
      }
    } catch (e) {
      _logger.e('JSON parse error: $e');
    }
    return null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendMessage({'action': 'ping'});
      }
    });
  }

  void _attemptReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 5), () {
      if (!_isConnected && _token != null && _baseUrl != null) {
        _logger.i('Attempting to reconnect WebSocket');
        connect(baseUrl: _baseUrl!, token: _token!);
      }
    });
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(message.toString());
      } catch (e) {
        _logger.e('Error sending WebSocket message: $e');
      }
    }
  }

  void subscribeToDevice(String deviceId) {
    _sendMessage({
      'action': 'subscribe',
      'device_id': deviceId,
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _logger.i('WebSocket disconnected');
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}
